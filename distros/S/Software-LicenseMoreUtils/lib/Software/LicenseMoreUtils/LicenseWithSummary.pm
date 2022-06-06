#
# This file is part of Software-LicenseMoreUtils
#
# This software is copyright (c) 2018, 2022 by Dominique Dumont.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Software::LicenseMoreUtils::LicenseWithSummary;
$Software::LicenseMoreUtils::LicenseWithSummary::VERSION = '1.009';
# ABSTRACT: Software::License with a summary

use strict;
use warnings;
use 5.10.1;

use Path::Tiny;
use YAML::Tiny;
use List::Util qw/first/;
use Carp;
use Text::Template;

our $AUTOLOAD;

# map location of distro file (like /etc/redhat_release) to distro.
# must match a <distro>_summaries.yml file in the directory containing
# this Perl module file
my %path_to_distro = (
    '/etc/debian_version' => 'debian',
);

my $distro_file = first { -e $_ } keys %path_to_distro;
my $distro = $path_to_distro{$distro_file // ''} || 'unknown';

(my $module_file = __PACKAGE__.'.pm' ) =~ s!::!/!g;
my $yml_file = path($INC{$module_file})->parent->child("$distro-summaries.yml") ;

my $summaries = {} ;
if ($yml_file->is_file) {
    $summaries = YAML::Tiny->read($yml_file)->[0];
}

sub new {
    my ($class, $args) = @_;
    my $self = {
        license => $args->{license},
        or_later => $args->{or_later},
        holder => $args->{holder},
    };

    return bless $self, $class;
}

sub distribution { return $distro }

sub summary {
    my $self = shift;

    my $later_text = $self->{or_later} ? ", or (at\nyour option) any later version" : '';

    (my $section_name = ref( $self->{license} )) =~ s/.*:://;
    my $summary = $summaries->{$section_name} // '';

    my $template = Text::Template->new(
        TYPE => 'STRING',
        DELIMITERS => [ qw({{ }}) ],
        SOURCE => $summary
    );

    return $template->fill_in(
        HASH => { or_later_clause => $later_text },
    );
}

sub license_class {
    my $self = shift;
    return ref($self->{license});
}

sub debian_text {
    my $self = shift;
    carp "debian_text is deprecated, please use summary_or_text";
    return $self->summary_or_text;
}

sub summary_or_text {
    my ($self) = @_;
    my $text;
    if (length $self->summary and $self->{holder}) {
        $text = join("\n",  grep { $_ } ($self->notice, $self->summary));
    }
    elsif (length $self->summary) {
        $text = $self->summary;
    }
    elsif ($self->{holder}) {
        $text =  $self->fulltext;
    }
    else {
        $text = $self->license;
    }
    return $text;
}

sub AUTOLOAD {
    my ($self, @args) = @_;
    my $lic = $self->{license};
    my ($sub) = ($AUTOLOAD =~ /(\w+)$/);
    if ($lic and $sub ne 'DESTROY') {
        return $lic->$sub(@args);
    }
    else {
        return;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::LicenseMoreUtils::LicenseWithSummary - Software::License with a summary

=head1 VERSION

version 1.009

=head1 SYNOPSIS

See L<Software::LicenseMoreUtils>. This class should be created with
  L<Software::LicenseMoreUtils/new_from_short_name>

=head1 DESCRIPTION

This module provides a wrapper around all C<Software::License::*> to add
a summary.

=head1 Methods

This class provides all the methods of the underlying
L<Software::License> object and the following methods.

=head2 summary

Returns the license summary, or an empty string.

=head2 summary_or_text

Returns the license summary or the text of the license. Like
L<Software::License/fulltext>, this method also returns the copyright
notice B<if> C<holder> parameter was set when calling
L<Software::LicenseMoreUtils/new_from_short_name>.

=head2 distribution

Returns the name of the Linux distribution found by this module. This
method is intended for tests or debugging.

=head2 license_class

Returns the Perl class name of the underlying L<Software::License> object.
E.g. C<Software::License::AGPL_3>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2022 by Dominique Dumont.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
