#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use autodie;

use Path::Class qw/dir/;
use Getopt::Long;
use Pod::Usage;
use MIME::Base64;

use Plack::MIME;
use Plack::App::DataSection;

=head1 DESCRIPTION

    convert script dir to perl data section.

=head1 SYNOPSIS

    % dir2data_section.pl --dir=dir --module=Your::Module

=cut

my %args;
GetOptions(
    \%args,
    'help',
    'dir=s',
    'module=s',
) or die pod2usage(2);
pod2usage(1) if $args{help};
pod2usage(2) unless $args{dir};

my $base_dir = $args{dir};
my @data_sections;

dir($base_dir)->recurse(
    callback => sub {
        my $file = shift;
        return unless -f $file;

        push @data_sections, data_section_single($file, $base_dir);
    }
);

my $data_section = join "\n", @data_sections;

if ($args{module}) {
    my $file_content = <<"...";
package $args{module};
use strict;
use warnings;
use parent 'Plack::App::DataSection';
1;
__DATA__
$data_section
...

    my $file_name = $args{module};
    $file_name =~ s/^.*:://;
    $file_name .= '.pm';

    open my $fh, '>', $file_name;
    print $fh $file_content;
}
else {
    print $data_section;
}

## subs
sub data_section_single {
    my ($file, $base_dir) = @_;

    my $data_section = '@@ '. $file->relative($base_dir) ."\n";
    my $content = $file->slurp;
    if (is_binary_by_file($file)) {
        $content = encode_base64($content);
    }
    $data_section .= $content;
}

sub is_binary_by_file {
    my $file = shift;

    my $mime_type = Plack::MIME->mime_type($file) || 'text/plain';
    Plack::App::DataSection::is_binary($mime_type);
}

