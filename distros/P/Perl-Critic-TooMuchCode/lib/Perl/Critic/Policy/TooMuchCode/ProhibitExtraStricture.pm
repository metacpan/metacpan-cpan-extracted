package Perl::Critic::Policy::TooMuchCode::ProhibitExtraStricture;
use strict;
use warnings;
use version 0.77;
use Perl::Critic::Utils ':booleans';
use Perl::Critic::Utils::Constants qw(@STRICT_EQUIVALENT_MODULES);
use parent 'Perl::Critic::Policy';

sub default_themes       { return qw( maintenance )     }
sub applies_to           { return 'PPI::Document' }

sub supported_parameters {
    return (
        {
            name        => 'stricture_modules',
            description => 'Modules which enables strictures.',
            behavior    => 'string list',
            list_always_present_values => [
                @STRICT_EQUIVALENT_MODULES,
                'Test2::V0',
            ],
        }
    );
}

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my @violations;
    my @includes = grep { $_->type eq "use" } @{ $doc->find('PPI::Statement::Include') ||[] };
    my @st_strict_pragma = grep { $_->pragma eq "strict" } @includes;
    my $version_statement = $doc->find_first( sub { $_[1]->version } );

    if (@st_strict_pragma == 1) {
        my %is_stricture_module = %{$self->{_stricture_modules}};

        my @st_strict_module = grep { $is_stricture_module{ $_ } } map { $_->module } @includes;

        if ($version_statement) {
            my $version = version->parse( $version_statement->version );

            if ( $version >= qv('v5.11.0') ) {
                push @st_strict_module, $version;
            }
        }

        if (@st_strict_module) {
            push @violations, $self->violation(
                "This `use strict` is redundant since ". $st_strict_module[0] . " also in place",
                "stricture is implied when using " . $st_strict_module[0] . ". Therefore there is no need to `use strict` in the same scope.",
                $st_strict_pragma[0],
            )
        }
    }

    return @violations;
}


1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitExtraStricture -- Find unnecessary 'use strict'

=head1 DESCRIPTION

Code stricture is good but that does not mean you always need to put
C<use strict> in your code. Several other modules enable code
stricture in the current scope, effectively the same having C<use strict>

Here's a list of those modules:

    Moose
    Mouse
    Moo
    Mo
    Moose::Role
    Mouse::Role
    Moo::Role
    Test2::V0

When one of these modules are used, C<use strict> is considered redundant
and is marked as violation by this policy.

=head2 Configuration

The builtin list of stricture modules is obviously not
comprehensive. You could extend the list by setting the
C<stricture_modules> in the config.  For example, with the following
setting, two modules, C<Foo> and C<Bar>, are appended to the list of
stricture modules.

    [TooMuchCode::ProhibitExtraStricture]
    stricture_modules = Foo Bar


=cut

1;
