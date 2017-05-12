package Module::Checkstyle::Check::Label;

use strict;
use warnings;

use Carp qw(croak);
use Readonly;

use Module::Checkstyle::Util qw(:args :problem);

use base qw(Module::Checkstyle::Check);

# The directives we provide

Readonly my $MATCHES_NAME      => 'matches-name';
Readonly my $POSITION          => 'position';
Readonly my $REQUIRE_FOR_BREAK => 'require-for-break';

sub register {
    return (
            'PPI::Token::Label'        => \&handle_label,
            'PPI::Statement::Break'    => \&handle_break,
        );
}

sub new {
    my ($class, $config) = @_;
    
    my $self = $class->SUPER::new($config);
    
    # Keep configuration local
    $self->{$MATCHES_NAME}       = as_regexp($config->get_directive($MATCHES_NAME));

    my $position = $config->get_directive($POSITION);
    if ($position) {
        croak qq/Invalid setting '$position' for directive '$POSITION' in [Label]/ if !is_valid_position($position);
        $self->{$POSITION} = lc($position);
    }

    $self->{$REQUIRE_FOR_BREAK} = as_true($config->get_directive($REQUIRE_FOR_BREAK));
    
    return $self;
}

sub handle_label {
    my ($self, $label, $file) = @_;

    my @problems;
    
    if ($self->{$MATCHES_NAME}) {
        my ($name) = $label->content() =~ /(.*):$/;
        if ($name && $name !~ $self->{$MATCHES_NAME}) {
                push @problems, new_problem($self->config, $MATCHES_NAME,
                                             qq(Label '$label' does not match '$self->{$MATCHES_NAME}'),
                                             $label, $file);
        }
    }

    if ($self->{$POSITION}) {
        my $next = $label->snext_sibling;
        
        if ($self->{$POSITION} eq 'alone') {
            # Find first previous non-whitespace token
            my $prev = do {
                my $p = $label->previous_token;
                while ($p && $p->isa('PPI::Token::Whitespace')) {
                    $p = $p->previous_token;
                }
                $p;
            };
            
           # On single line
            if (($prev && $prev->location->[0] == $label->location->[0]) or
                ($next && $next->location->[0] == $label->location->[0])) {
                push @problems, new_problem($self->config, $POSITION,
                                            qq(Label '$label' is not on a line by its own),
                                            $label, $file);
            }
        }
        else {
            # On same line
            if ($next && $next->location->[0] != $label->location->[0]) {
                push @problems, new_problem($self->config, $POSITION,
                                            qq(Label '$label' is not on the same line as '$next'),
                                            $label, $file);
            }
        }
    }
    
    return @problems;
}

sub handle_break {
    my ($self, $break, $file) = @_;

    my @problems;

    if ($self->{$REQUIRE_FOR_BREAK} && $break->first_token->content =~ /^last|next|redo$/) {
        # next significan should be word
        my $next = do {
            my $n = $break->schild(0)->next_token;
            while ($n && $n->isa('PPI::Token::Whitespace')) {
                $n = $n->next_token;
            }
            $n;
        };

        if (($next && !$next->isa('PPI::Token::Word')) or
            ($next && $next->isa('PPI::Token::Word') && $next->content =~ /^if|unless$/)) {
            my $break_type = $break->first_token->content;
            push @problems, new_problem($self->config, $REQUIRE_FOR_BREAK,
                                        qq(Break '$break_type' used without a label),
                                        $break, $file);
        }

    }
    
    return @problems;
}

1;
__END__

=head1 NAME

Module::Checkstyle::Check::Label - Checks label declarations and usage

=head1 CONFIGURATION DIRECTIVES

=over 4

=item Label name

Checks that a label is named correctly. Use I<matches-name> to specify a regular expression that must match.

C<matches-name = qr/^(?:[A-Z]+_)*[A-Z]+$/>

=item Label position

Checks that a label is positioned correctly. Use I<position> to specify either 'alone' or 'same'.

  # position = alone
  LABEL:
    while (1) {
    }

  # position = same
  LABEL: while(1) {
  }

C<position = alone | same>

=item Require label for break statements

Checks that C<last>, C<next> and C<redo> are called with a label. Set I<require-for-break> to enable.

C<require-for-break = true>

=back

=begin PRIVATE

=head1 METHODS

=over 4

=item register

Called by C<Module::Checkstyle> to get events we respond to.

=item new ($config)

Creates a new C<Module::Checkstyle::Check::Length> object.

=item handle_label ($label, $file)

Called when we encounter a C<PPI::Token::Label> element.

=item handle_break ($break, $file)

Called when we encounter a C<PPI::Statement::Break> element.

=back

=end PRIVATE

=head1 SEE ALSO

Writing configuration files. L<Module::Checkstyle::Config/Format>

L<Module::Checkstyle>

=cut
