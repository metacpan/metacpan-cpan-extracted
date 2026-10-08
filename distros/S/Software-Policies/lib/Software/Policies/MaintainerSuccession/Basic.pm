package Software::Policies::MaintainerSuccession::Basic;
## no critic (ControlStructures::ProhibitPostfixControls)

use strict;
use warnings;
use 5.010;

# ABSTRACT: Create project policy file: MaintainerSuccession / Basic

our $VERSION = '0.006';

use Carp;
use Data::Section -setup;
use Text::Template ();

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub create {
    my ( $self, %args ) = @_;
    my $version = delete $args{'version'} // '1';
    my $format  = delete $args{'format'}  // 'markdown';

    my %attributes;
    my $attrs = delete $args{'attributes'} // {};
    croak q{Unknown arguments: }, join q{,}, keys %args if (%args);

    foreach (qw( authors )) {
        $attributes{$_} = $attrs->{$_};
    }

    # N.B. We do not check for unknown attributes because:
    # 1. Dist::Zilla passes most of attributes
    # 2. User can have his own classes or versions

    my @missing_attributes;
    foreach (qw( authors )) {
        push @missing_attributes, $_ if ( !defined $attributes{$_} );
    }
    croak q{Missing attributes: } . join q{,}, @missing_attributes
      if (@missing_attributes);

    $attributes{'contact'} = $attributes{'authors'}->[0];
    delete $attributes{'authors'};
    $attributes{'tools'} = delete $attributes{'ai_tools'};

    my ($data_section)     = __PACKAGE__ =~ m/.+::([^:]+)$/msx;
    my $data_section_label = $data_section . q{_v} . $version . q{_} . $format;
    my $template           = $self->section_data($data_section_label);
    croak "Cannot find data section $data_section_label"
      if ( !$template );
    my $text = Text::Template->fill_this_in(
        ${$template},
        HASH       => \%attributes,
        DELIMITERS => [qw/{{ }}/],
    );
    return (
        policy   => 'MaintainerSuccession',
        class    => 'Basic',
        version  => $version,
        text     => $text,
        filename => _filename($format),
        format   => $format,
    );
}

sub get_available_classes_and_versions {
    return {
        'Basic' => {
            versions => {
                '1' => 1,
            },
            formats => {
                'markdown' => 1,
                'pod'      => 1,
            },
        },
    };
}

sub _filename {
    my ($format) = @_;
    my %formats = (
        'markdown' => 'MAINTAINER_SUCCESSION.md',
        'pod'      => 'MAINTAINER_SUCCESSION.pod'
    );
    return $formats{$format};
}

1;

=pod

=encoding UTF-8

=head1 NAME

Software::Policies::MaintainerSuccession::Basic - Create project policy file: MaintainerSuccession / Basic

=head1 VERSION

version 0.006

=for Pod::Coverage new create get_available_classes_and_versions

=for :stopwords maintainership

=head1 METHODS

=head2 new

=head2 create

Create the policy.

Options:

=over 8

=item class

Available classes: B<Basic> (default).

=item version

Available versions: 1 (default).

=item format

Available formats: markdown (default).

=item attributes

=over 8

=item authors

Required attribute for contact information.

=back

=back

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__[ Basic_v1_markdown ]__
# ADOPTION

If you're interested in adopting this module, and the author/maintainer
appears to be no longer active, please consult the PAUSE module
adoption process documented at
https://metacpan.org/about/faq#how-to-adopt-a-distribution.

The PAUSE admins (modules@perl.org) may grant co-maintainer or
primary-maintainer permissions to a suitable adopter if:

- There has been no release for a year or more, AND
- There are outstanding issues, pull requests, or bug reports that would
  benefit from attention, AND
- Reasonable attempts to contact me have failed, for example:
  email {{ $contact }},
  GitHub issues on the project repository, and any other channels listed
  in this distribution, over a period of at least one month, AND
- The prospective adopter intends to make changes that benefit users of
  the module.

In the event of my death or permanent incapacity, my heirs are not
obligated to maintain these modules, and I explicitly authorize the
PAUSE admins to transfer maintainership without further consultation
once the conditions above are met.
__[ Basic_v1_pod ]__
=head1 ADOPTION

If you're interested in adopting this module, and the author/maintainer
appears to be no longer active, please consult the PAUSE module
adoption process documented at
L<https://metacpan.org/about/faq#how-to-adopt-a-distribution>.

The PAUSE admins (modules@perl.org) may grant co-maintainer or
primary-maintainer permissions to a suitable adopter if:

=over 4

=item *

There has been no release for a year or more, AND

=item *

There are outstanding issues, pull requests, or bug reports that would
benefit from attention, AND

=item *

Reasonable attempts to contact me have failed, for example:
email {{ $contact }},
GitHub issues on the project repository, and any other channels listed
in this distribution) over a period of at least one month, AND

=item *

The prospective adopter intends to make changes that benefit users of
the module.

=back

In the event of my death or permanent incapacity, my heirs are not
obligated to maintain these modules, and I explicitly authorize the
PAUSE admins to transfer maintainership without further consultation
once the conditions above are met.

=cut
