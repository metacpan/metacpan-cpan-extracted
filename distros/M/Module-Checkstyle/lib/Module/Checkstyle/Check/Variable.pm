package Module::Checkstyle::Check::Variable;

use strict;
use warnings;

use Carp qw(croak);
use Lingua::EN::Inflect::Number qw(number);
use Readonly;

use Module::Checkstyle::Util qw(:args :problem);

use base qw(Module::Checkstyle::Check);

# The directives we provide
Readonly my $MATCHES_NAME         => 'matches-name';
Readonly my $ARRAYS_IN_PLURAL     => 'arrays-in-plural';
Readonly my $HASHES_IN_SINGULAR   => 'hashes-in-singular';

sub register {
    return (
            'PPI::Statement::Variable' => \&handle_declaration,
        );
}

sub new {
    my ($class, $config) = @_;
    
    my $self = $class->SUPER::new($config);
    
    # Keep configuration local
    $self->{$MATCHES_NAME}       = as_regexp($config->get_directive($MATCHES_NAME));
    $self->{$ARRAYS_IN_PLURAL}   = as_true($config->get_directive($ARRAYS_IN_PLURAL));
    $self->{$HASHES_IN_SINGULAR} = as_true($config->get_directive($HASHES_IN_SINGULAR));

    return $self;
}

sub handle_declaration {
    my ($self, $declaration, $file) = @_;

    my @variables = $declaration->variables();
    return $self->_check_variables($declaration, $file, @variables);
}

sub _check_variables {
    my ($self, $declaration, $file, @variables) = @_;

    my @problems;

  CHECK_VARIABLE:
    foreach my $variable (@variables) {
        my $type = substr($variable, 0, 1);
        my $name = substr($variable, 1);

        # Ignore "built-in" arrays and hashes
        next CHECK_VARIABLE if $type eq '@' && $name =~ /^ISA|EXPORT|EXPORT_OK$/;
        next CHECK_VARIABLE if $type eq '%' && $name =~ /^EXPORT_TAGS$/;

        # matches-name
        if ($self->{$MATCHES_NAME}) {
            if ($name && $name !~ $self->{$MATCHES_NAME}) {
                push @problems, new_problem($self->config, $MATCHES_NAME,
                                             qq(Variable '$variable' does not match '$self->{$MATCHES_NAME}'),
                                             $declaration, $file);
            }
        }

        # arrays-in-plural
        if ($type eq '@' && $self->{$ARRAYS_IN_PLURAL}) {
            my ($last_word) = $name =~ /([A-Z]?(?:[a-z0-9]+|[A-Z0-9]+))$/;
            if (number(lc($last_word)) ne 'p') {
                push @problems, new_problem($self->config, $ARRAYS_IN_PLURAL,
                                             qq(Variable '$variable' is an array and must be named in plural),
                                             $declaration, $file);
            }
        }

        # hashes-in-singular
        if ($type eq '%' && $self->{$HASHES_IN_SINGULAR}) {
            my ($last_word) = $name =~ /([A-Z]?(?:[a-z0-9]+|[A-Z0-9]+))$/;
            if (number(lc($last_word)) ne 's') {
                push @problems, new_problem($self->config, $HASHES_IN_SINGULAR,
                                             qq(Variable '$variable' is an hash and must be named in singular),
                                             $declaration, $file);
            }
        }
    }
    
    return @problems;
}

1;
__END__

=head1 NAME

Module::Checkstyle::Check::Variable - Checks variable declarations

=head1 LIMITATIONS

The checks provided by this module currently only works for variables declared using B<my>, B<our> or B<local>.
It may in the future also support C<use vars qw(...);> style declarations.

The checks I<arrays-in-plural> and I<hashes-in-singular> works best with the english language and may not always
be correct. Internally it uses L<Lingua::EN::Inflect::Number> that relies on L<Lingua::EN::Inflect> do determine
plural/singular forms.

=head1 CONFIGURATION DIRECTIVES

=over 4

=item Variable name

Checks that a variable is named correctly. Use I<matches-name> to specify a regular expression that must match.

C<matches-name = qr/\w+/>

=item Name arrays in plural

Checks that an array has a plural name as in C<@values> but not C<@value>. Set I<arrays-in-plural> to a true value to enable.

C<arrays-in-plural = true>

=item Name hashes in singular

Checks that a hash has a singular name as in C<%key> but not C<%keys>. Set I<hashes-in-singular> to a true value to enable.

C<hashes-in-singular = true>

=back

=begin PRIVATE

=head1 METHODS

=over 4

=item register

Called by C<Module::Checkstyle> to get events we respond to.

=item new ($config)

Creates a new C<Module::Checkstyle::Check::Length> object.

=item handle_declaration ($declaration, $file)

Called when we encounter a C<PPI::Statement::Variable> element.

=item _check_variables ($element, $file, @variables)

Called by C<handle_declaration> to do variable checks.

=back

=end PRIVATE

=head1 SEE ALSO

Writing configuration files. L<Module::Checkstyle::Config/Format>

L<Module::Checkstyle>

L<Lingua::EN::Inflect::Number>

L<Lingua::EN::Inflect>

=cut
