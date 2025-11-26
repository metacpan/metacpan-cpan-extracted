## no critic (ControlStructures::ProhibitPostfixControls)
package Software::Policies::CodeOfConduct::ContributorCovenant;

use strict;
use warnings;
use 5.010;

# ABSTRACT: Create a policy file: Code of Conduct / Contributor Covenant

our $VERSION = '0.001';

use Carp;
use Software::Policy::CodeOfConduct;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub create {
    my ( $self, %args ) = @_;
    my $version = $args{'version'} // '1.4';
    my $format  = $args{'format'}  // 'markdown';
    my %attributes;
    my $attrs = $args{'attributes'} // {};
    $attributes{'policy'}  = 'Contributor_Covenant_' . $version;
    $attributes{'name'}    = $attrs->{'name'}         if $attrs->{'name'};
    $attributes{'contact'} = $attrs->{'authors'}->[0] if $attrs->{'authors'};
    croak q{Missing attribute 'name'}    if ( !defined $attributes{'name'} );
    croak q{Missing attribute 'contact'} if ( !defined $attributes{'contact'} );

    my $p = Software::Policy::CodeOfConduct->new(

        # policy   => 'Contributor_Covenant_1.4',
        # name     => 'Foo',
        # contact  => 'team-foo@example.com',
        # filename => 'CODE_OF_CONDUCT.md',
        %attributes,
    );

    return (
        policy   => 'CodeOfConduct',
        class    => 'ContributorCovenant',
        version  => $version,
        text     => $p->fulltext . "\n",
        filename => _filename($format),
        format   => $format,
    );
}

sub get_available_classes_and_versions {
    return {
        'ContributorCovenant' => {
            versions => {
                '1.4' => 1,
                '2.0' => 1,
                '2.1' => 1,
            },
            formats => {
                'markdown' => 1,
            },
        },
    };
}

sub _filename {
    my ($format) = @_;
    my %formats = ( 'markdown' => 'CODE_OF_CONDUCT.md', );
    return $formats{$format};
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Policies::CodeOfConduct::ContributorCovenant - Create a policy file: Code of Conduct / Contributor Covenant

=head1 VERSION

version 0.001

=head1 SYNOPSIS

=head1 DESCRIPTION

=begin Pod::Coverage




=end Pod::Coverage

=begin stopwords




=end stopwords

=head1 METHODS

=head2 new

=head2 create

Create the policy.

Options:

=over 8

=item class

Available classes: B<Simple> (default).

=item version

Available versions: 1 (default).

=item format

Available formats: markdown (default).

=item attributes

Required attributes:

=over 8

=item name

=item authors

=back

=back

=head2 get_available_classes_and_versions

Return a hash with classes as keys. Example:

    {
        'ContributorCovenant' => {
            versions => {
                '1.4' => 1,
                '2.0' => 1,
                '2.1' => 1,
            },
            formats => {
                'markdown' => 1,
            },
        },
    }

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
