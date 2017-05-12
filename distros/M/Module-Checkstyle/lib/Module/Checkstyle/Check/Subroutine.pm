package Module::Checkstyle::Check::Subroutine;

use strict;
use warnings;

use Carp qw(croak);
use Readonly;

use Module::Checkstyle::Util qw(:args :problem);

use base qw(Module::Checkstyle::Check);

# The directives we provide
Readonly my $MATCHES_NAME => 'matches-name';
Readonly my $MAX_LENGTH   => 'max-length';
Readonly my $NO_FQN       => 'no-fully-qualified-names';
Readonly my $NO_AMP_CALLS => 'no-calling-with-ampersand';

sub register {
    return (
            'enter PPI::Statement::Sub' => \&handle_subroutine,
            'PPI::Token::Symbol'        => \&handle_symbol,
        );
}

sub new {
    my ($class, $config) = @_;
    
    my $self = $class->SUPER::new($config);
    
    # Keep configuration local
    $self->{$MATCHES_NAME} = as_regexp($config->get_directive($MATCHES_NAME));
    $self->{$MAX_LENGTH}   = as_numeric($config->get_directive($MAX_LENGTH));
    $self->{$NO_FQN}       = as_true($config->get_directive($NO_FQN));
    $self->{$NO_AMP_CALLS} = as_true($config->get_directive($NO_AMP_CALLS));
    
    return $self;
}

sub handle_subroutine {
    my ($self, $subroutine, $file) = @_;

    my @problems;

    push @problems, $self->_handle_naming($subroutine, $file);
    
    # Length
    if ($self->{$MAX_LENGTH}) {
        my $block = $subroutine->block();
        # Forward declarations has no block hence no length to check
        if (defined $block) {
            my $first_line = $subroutine->location()->[0];
            my $last_line  = $block->last_element()->location()->[0];
            my $length = $last_line - $first_line;
            if ($length > $self->{$MAX_LENGTH}) {
                my $name = $subroutine->name();
                push @problems, new_problem($self->config, $MAX_LENGTH,
                                             qq(Subroutine '$name' is too long ($length lines)),
                                             $subroutine, $file);
            }
        }
    }
    
    return @problems;
}

sub _handle_naming {
    my ($self, $subroutine, $file) = @_;

    my @problems;

    # Naming
    if ($self->{$MATCHES_NAME}) {
        my $name = $subroutine->name();
        if ($name && $name !~ $self->{$MATCHES_NAME}) {
            push @problems, new_problem($self->config, $MATCHES_NAME,
                                         qq(Subroutine '$name' does not match '$self->{$MATCHES_NAME}'),
                                         $subroutine, $file);
        }
    }

    # Qualified names
    if ($self->{$NO_FQN}) {
        my $name = $subroutine->name();
        if ($name && $name =~ m{ :: | \' }x) {
            push @problems, new_problem($self->config, $NO_FQN,
                                         qq(Subroutine '$name' is fully qualified),
                                         $subroutine, $file);
        }
    }
    
    return @problems;
}

sub handle_symbol {
    my ($self, $symbol, $file) = @_;

    # We're only interested in what can be subroutine calls
    return if $symbol->symbol_type() ne '&';

    my @problems;
    
    if ($self->{$NO_AMP_CALLS}) {
        my $next_sibling = $symbol->snext_sibling();
        if ($next_sibling && ref $next_sibling && $next_sibling->isa('PPI::Structure::List')) {
            my $name = substr($symbol->content(), 1);
            push @problems, new_problem($self->config, $NO_AMP_CALLS,
                                         qq(Calling subroutine '$name' with ampersand),
                                         $symbol, $file);
        }
    }

    return @problems;
}

1;
__END__

=head1 NAME

Module::Checkstyle::Check::Subroutine - Checks length, naming etc. of named subroutines

=head1 CONFIGURATION DIRECTIVES

=over 4

=item Subroutine name

Checks that a subroutine is named correctly. Use I<matches-name> to specify a regular expression that must match.

C<matches-name = qr/\w+/>

=item Subroutine length

Checks that named subroutines doesn't exceed a specified length. Use I<max-length> to specify the maximum number of lines a subroutine may be.

C<max-length = 40>

=item No declaration of subroutines with a fully qualified name

Checks if a subroutine is declared with a fully qualified name. That if it contains :: or '. Set I<no-fully-qualified-names> to a true value to enable.

C<no-fully-qualified-names = true>

=item Calling subroutines with ampersand

Checks if a subroutine is called with an ampersand (like Perl4). This check ignores calls with ampersand to functions where there are no arguments to honor shared @_. Set I<no-calling-with-ampersand> to a true value to enable.

C<no-calling-with-ampersand = true>

=back

=begin PRIVATE

=head1 METHODS

=over 4

=item register

Called by C<Module::Checkstyle> to get events we respond to.

=item new ($config)

Creates a new C<Module::Checkstyle::Check::Length> object.

=item handle_subroutine ($subroutine, $file)

Called when we encounter a C<PPI::Statement::Sub> element.

=item _handle_naming ($subroutine, $file)

Called by C<handle_subroutine> to do naming checks.

=item handle_symbol ($symbol, $file)

Called when we encounter a C<PPI::Token::Symbol> element.

=back

=end PRIVATE

=head1 SEE ALSO

Writing configuration files. L<Module::Checkstyle::Config/Format>

L<Module::Checkstyle>

=cut
