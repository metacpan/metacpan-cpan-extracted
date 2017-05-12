package Module::Checkstyle::Check::Whitespace;

use strict;
use warnings;

use Carp qw(croak);
use Readonly;

use Module::Checkstyle::Util qw(:problem :args);

use base qw(Module::Checkstyle::Check);

# The directives we provide
Readonly my $AFTER_COMMA        => 'after-comma';
Readonly my $BEFORE_COMMA       => 'before-comma';
Readonly my $AFTER_FAT_COMMA    => 'after-fat-comma';
Readonly my $BEFORE_FAT_COMMA   => 'before-fat-comma';
Readonly my $AFTER_COMPOUND     => 'after-compound';

sub register {
    return (
            'PPI::Token::Operator'     => \&handle_operator,
            'PPI::Statement::Compound' => \&handle_compound,
        );
}

sub new {
    my ($class, $config) = @_;
    
    my $self = $class->SUPER::new($config);
    
    # Keep configuration local
    foreach ($AFTER_COMMA, $BEFORE_COMMA, $AFTER_FAT_COMMA, $BEFORE_FAT_COMMA, $AFTER_COMPOUND) {
        $self->{$_} = as_true($config->get_directive($_));
    }

    return $self;
}

sub handle_operator {
    my ($self, $operator, $file) = @_;

    my @problems;

    push @problems, $self->_handle_comma($operator, $file);
    push @problems, $self->_handle_fat_comma($operator, $file);
    
    return @problems;
}

sub _handle_comma {
    my ($self, $operator, $file) = @_;

    my @problems;

    if ($operator->content() eq ',') {
        if ($self->{$AFTER_COMMA}) {
            # Next sibling should be whitespace
            my $sibling = $operator->next_sibling();
            if ($sibling && ref $sibling && !$sibling->isa('PPI::Token::Whitespace')) {
                push @problems, new_problem($self->config, $AFTER_COMMA,
                                             qq(Missing whitespace after comma (,)),
                                             $operator, $file);
            }
        }
        
        if ($self->{$BEFORE_COMMA}) {
            # Previous sibling should be whitespace
            my $sibling = $operator->previous_sibling();
            if ($sibling && ref $sibling && !$sibling->isa('PPI::Token::Whitespace')) {
                push @problems, new_problem($self->config, $BEFORE_COMMA,
                                             qq(Missing whitespace before comma (,)),
                                             $operator, $file);
            }
        }
    }

    return @problems;
}

sub _handle_fat_comma {
    my ($self, $operator, $file) = @_;

    my @problems;
    
    if ($operator->content() eq '=>') {
        if ($self->{$AFTER_FAT_COMMA}) {
            # Next sibling should be whitespace
            my $sibling = $operator->next_sibling();
            if ($sibling && ref $sibling && !$sibling->isa('PPI::Token::Whitespace')) {
                push @problems, new_problem($self->config, $AFTER_FAT_COMMA,
                                             qq(Missing whitespace after fat comma (=>)),
                                             $operator, $file);
            }
        }

        if ($self->{$BEFORE_FAT_COMMA}) {
            # Previous sibling should be whitespace
            my $sibling = $operator->previous_sibling();
            if ($sibling && ref $sibling && !$sibling->isa('PPI::Token::Whitespace')) {
                push @problems, new_problem($self->config, $BEFORE_FAT_COMMA,
                                             qq(Missing whitespace before fat comma (=>)),
                                             $operator, $file);
            }
        }
    }

    return @problems;
}

sub handle_compound {
    my ($self, $compound, $file) = @_;

    my @problems;

    if ($self->{$AFTER_COMPOUND}) {
        my @children = $compound->schildren();

      CHECK_COMPOUND_BLOCK:
        foreach my $child (@children) {
            next CHECK_COMPOUND_BLOCK if !$child->isa('PPI::Token::Word');
            my $word = $child->content();
            my $sibling = $child->next_sibling();
            if (defined $sibling && ref $sibling && !$sibling->isa('PPI::Token::Whitespace')) {
                push @problems, new_problem($self->config, $AFTER_COMPOUND,
                                             qq('$word' is not followed by whitespace),
                                             $child, $file);
            }
        }
    }

    return @problems;
}

1;
__END__

=head1 NAME

Module::Checkstyle::Check::Whitespace - Make sure whitespace is at correct places

=head1 CONFIGURATION DIRECTIVES

=over 4

=item Whitespace after comma

Checks that there is whitespace after a comma, for example as in C<my ($foo, $bar);>. Enable it by setting I<after-comma> to true.

C<after-comma = true>

=item Whitespace before comma

Checks that there is whitespace before a comma, for example as in C<my ($foo ,$bar);>. Enable it by setting I<before-comma> to 1.

C<before-comma = true>

=item Whitespace after fat comma

Checks that there is whitespace after a fat comma (=E<gt>), for example as in C<call(arg=E<gt> 1)>. Enable it by setting I<after-fat-comma> to true.

C<after-fat-comma = true>

=item Whitespace before fat comma

Checks that there is whitespace before a fat comma (=E<gt>), for example as in C<call(arg =E<gt>1)>. Enable it by setting I<before-fat-comma> to true.

C<before-fat-comma = true>

=item Whitespace after control keyword in compound statements

Checks that there is whitespace after a control-flow keyword in a compound statement. This means an if, elsif, else, while, for, foreach and continue (C<if (EXPR) { .. }>) but not when they are used as statement modifiers (C<... if EXPR>). For information on compound statements read L<perlsyn/Compound Statements>. Enable this check by setting I<after-compound> to a true value.

C<after-compound = true>

=back

=begin PRIVATE

=head1 METHODS

=over 4

=item register

Called by C<Module::Checkstyle> to get events we respond to.

=item new ($config)

Creates a new C<Module::Checkstyle::Check::Package> object.

=item handle_operator ($operator, $file)

Called when we encounter a C<PPI::Token::Operator> element.

=item _handle_comma ($operator, $file)

Called by C<handle_operator> to do comma checks.

=item _handle_fat_comma ($operator, $file)

Called by C<handle_operator> to do fat comma checks.

=item handle_compound ($compound, $file)

Called when we encounter a C<PPI::Statement::Compound> element.

=back

=end PRIVATE

=head1 SEE ALSO

Writing configuration files. L<Module::Checkstyle::Config/Format>

L<Module::Checkstyle>

=cut
