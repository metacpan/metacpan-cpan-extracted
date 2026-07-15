package Template::EmbeddedPerl::Arguments;

use strict;
use warnings;

use PPI::Document;

my %RESERVED_ARGUMENT = map { $_ => 1 } qw(__named_args __context _O self);

sub rewrite {
    my ($class, $template, %args) = @_;
    my $comment_mark = exists $args{comment_mark} ? $args{comment_mark} : '#';
    my $line_start = exists $args{line_start} ? $args{line_start} : '%';
    my $open_tag = exists $args{open_tag} ? $args{open_tag} : '<%';
    my $close_tag = exists $args{close_tag} ? $args{close_tag} : '%>';
    my @lines = $template =~ /.*?(?:\n|\z)/g;
    pop @lines if @lines && $lines[-1] eq '';

    my @directive_lines = grep {
        $lines[$_] =~ /^[ \t]*\Q$line_start\E[ \t]+args(?:[ \t]|\n|\z)/
    } 0 .. $#lines;
    return ($template, 0) unless @directive_lines;

    my $start = $directive_lines[0];
    for my $line_number (0 .. $start - 1) {
        next if $lines[$line_number] =~ /^[ \t]*(?:\n|\z)$/;
        next if defined($comment_mark) && length($comment_mark)
            && $lines[$line_number] =~ /^[ \t]*\Q$comment_mark\E[^\n]*(?:\n|\z)$/;
        _error('args must be the first executable directive', $start + 1);
    }

    my ($declaration, $end) = _collect_declaration(\@lines, $start, $line_start);
    for my $line_number ($end + 1 .. $#lines) {
        next unless $lines[$line_number]
            =~ /^[ \t]*\Q$line_start\E[ \t]+args(?:[ \t]|\n|\z)/;
        _error('args directive may only appear once', $line_number + 1);
    }

    my $expected_newlines = $declaration =~ tr/\n//;
    my $line_boundary = $declaration =~ s/\n\z// ? "\n" : '';
    my $generated = _generate_bindings($declaration, $start + 1);
    my $actual_newlines = $generated =~ tr/\n//;
    my $generated_newlines = $expected_newlines - ($line_boundary eq "\n" ? 1 : 0);
    _error('args rewrite could not preserve source lines', $start + 1)
        if $actual_newlines > $generated_newlines;
    $generated .= "\n" x ($generated_newlines - $actual_newlines);

    splice @lines, $start, $end - $start + 1,
        "${open_tag}${generated}-${close_tag}${line_boundary}";
    return (join('', @lines), 1);
}

sub _collect_declaration {
    my ($lines, $start, $line_start) = @_;
    my $declaration = $lines->[$start];
    $declaration =~ s/^[ \t]*\Q$line_start\E[ \t]+args\b//;

    my $end = $start;
    while (!_is_complete($declaration)) {
        $end++;
        if ($end > $#$lines
            || $lines->[$end] !~ /^[ \t]*\Q$line_start\E(?!\Q$line_start\E)/) {
            my $message = $declaration =~ /=\s*(?:\n)?\z/
                ? 'args default expression is incomplete'
                : 'incomplete args directive';
            _error($message, $start + 1);
        }

        my $continuation = $lines->[$end];
        $continuation =~ s/^[ \t]*\Q$line_start\E//;
        $declaration .= $continuation;
    }

    return ($declaration, $end);
}

sub _is_complete {
    my ($declaration) = @_;
    my ($document, $list, $expression) = _parse_declaration($declaration);
    return 0 unless $document && $list && $expression;

    my $structures = $document->find('PPI::Structure');
    return 0 if $structures && grep { !$_->finish } @$structures;
    return 0 if $document->find('PPI::Statement::UnmatchedBrace');

    my @tokens = grep { $_->significant } $expression->tokens;
    return 0 unless @tokens;
    return 0 if $tokens[-1]->isa('PPI::Token::Operator');
    return 1;
}

sub _generate_bindings {
    my ($declaration, $line) = @_;
    my ($document, $list, $expression) = _parse_declaration($declaration);
    _error('invalid args directive', $line)
        unless $document
            && $list
            && $expression
            && _is_wholly_consumed($document, $list, $expression);

    my @parts;
    my @part;
    for my $element ($expression->children) {
        if ($element->isa('PPI::Token::Operator') && $element->content eq ',') {
            push @parts, [@part];
            @part = ();
            next;
        }
        push @part, $element;
    }
    push @parts, [@part];

    my %seen;
    my $generated = 'my $__named_args=$__context->named_arguments(\@_);';
    for my $part (@parts) {
        my @significant = grep { $_->significant } @$part;
        _error('args directive requires a scalar argument', $line) unless @significant;

        my $symbol = shift @significant;
        _error('args directive accepts only scalar arguments', $line)
            unless $symbol->isa('PPI::Token::Symbol')
                && $symbol->content =~ /^\$([A-Za-z_]\w*)\z/;
        my $name = $1;
        _error("Template argument '$name' uses a reserved compiler identifier", $line)
            if $RESERVED_ARGUMENT{$name};
        _error("Duplicate args declaration '$name'", $line) if $seen{$name}++;

        my ($symbol_index) = grep { $part->[$_] == $symbol } 0 .. $#$part;
        my $leading = join '', map { $_->content } @$part[0 .. $symbol_index - 1];
        $generated .= $leading;

        if (!@significant) {
            $generated .= "my \$$name=\$__context->take_required_argument(\$__named_args,'$name');";
            next;
        }

        my $equals = shift @significant;
        _error("invalid declaration for template argument '$name'", $line)
            unless $equals->isa('PPI::Token::Operator') && $equals->content eq '=';
        _error("template argument '$name' requires a default expression", $line)
            unless @significant;

        my ($equals_index) = grep { $part->[$_] == $equals } 0 .. $#$part;
        my @default_elements = @$part[$equals_index + 1 .. $#$part];
        my $default = join '', map { $_->content } @default_elements;
        my @default_significant = grep { $_->significant } @default_elements;
        my $factory = _is_anonymous_sub(@default_significant)
            ? $default
            : "sub {$default}";
        $generated .= "my \$$name=\$__context->take_optional_argument(\$__named_args,'$name',$factory);";
    }

    $generated .= '$__context->assert_no_arguments($__named_args);';
    return $generated;
}

sub _is_anonymous_sub {
    my (@elements) = @_;
    return 0 unless @elements == 2 || @elements == 3;
    return 0 unless $elements[0]->isa('PPI::Token::Word') && $elements[0]->content eq 'sub';
    return 0 unless $elements[-1]->isa('PPI::Structure::Block');
    return 1 if @elements == 2;
    return $elements[1]->isa('PPI::Structure::List');
}

sub _is_wholly_consumed {
    my ($document, $list, $expression) = @_;
    my $statement = $document->schild(0) or return 0;
    return 0 unless $statement->isa('PPI::Statement::Variable');
    return 0 if $document->schild(1);

    my $keyword = $statement->schild(0) or return 0;
    return 0 unless $keyword->isa('PPI::Token::Word') && $keyword->content eq 'my';
    return 0 unless $statement->schild(1) == $list;

    my $terminator = $statement->schild(2) or return 0;
    return 0 unless $terminator->isa('PPI::Token::Structure')
        && $terminator->content eq ';';
    return 0 if $statement->schild(3);

    return 0 unless $list->schild(0) == $expression;
    return 0 if $list->schild(1);
    return 0 if grep {
        $_->isa('PPI::Token::Structure') && $_->content eq ';'
    } $expression->children;
    return 1;
}

sub _parse_declaration {
    my ($declaration) = @_;
    my $source = "my ($declaration);";
    my $document = PPI::Document->new(\$source) or return;
    my $statement = $document->schild(0) or return;
    my $list = $statement->find_first('PPI::Structure::List') or return;
    my $expression = $list->schild(0) or return;
    return ($document, $list, $expression);
}

sub _error {
    my ($message, $line) = @_;
    die "$message at template line $line\n";
}

1;
