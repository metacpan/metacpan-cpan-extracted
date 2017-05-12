#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Plugin::Minify::Perl;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Plugin::Minify::Perl - Perl code minifier plugin for the Nile framework.

=head1 SYNOPSIS
        
=head1 DESCRIPTION

Nile::Plugin::Minify::Perl - Perl code minifier plugin for the Nile framework.
    
    $app->plugin->minify->perl($output_file => $file1, $file2, $url1, $url2, ...);

    $app->plugin->minify->perl('app.pm' => '/file1.pm', '/file2.pm');
    
=cut

use Nile::Base;
use Perl::Tidy;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub process {

    my ($self, $out, @files) = @_;

    my $content = "";

    foreach my $file (@files) {
        $content .= $self->process_file($file);
    }

    $self->app->file->put($out, $content);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub process_file {
    
    my ($self, $file) = @_;
    
    my $source_string = $self->app->file->get($file);
    
    my $dest_string;
    my $stderr_string;
    my $errorfile_string;

    my $argv = "-npro";   # Ignore any .perltidyrc at this site

    $argv .= " -pbp";     # Format according to perl best practices
    $argv .= " -nst";     # Must turn off -st in case -pbp is specified
    $argv .= " -se";      # -se appends the errorfile to stderr
    $argv .= " -ci=0 -cti=0 -dac -sil=0";

    #-pbp is an abbreviation for the parameters in the book B<Perl Best Practices> by Damian Conway:
    #  -l=78 -i=4 -ci=4 -st -se -vt=2 -cti=0 -pt=1 -bt=1 -sbt=1 -bbt=1 -nsfs -nolq
    #  -wbb='% + - * / x != == >= <= =~ !~ < > | & = **= += *= &= <<= &&= -= /= |= >>= ||= //= .= %= ^= x='

    $argv = "-vt=0 -nolq -i=0 -sil=0 -ce -l=1024 -nbl -pt=2 -bt=2 -sbt=2 -bbt=2 -bvt=1 -sbvt=1 -pvtc=1 -cti=0 -ci=0 -nsfs -nsts -bar -dac -dbc -dsc -dp -sob -ce -mbl=0 -dws -ple ";
    $argv .= " -nsak='my our local' -naws ";

    my $error = Perl::Tidy::perltidy(
        argv        => $argv,
        source      => \$source_string,
        destination => \$dest_string,
        stderr      => \$stderr_string,
        errorfile   => \$errorfile_string,    # ignored when -se flag is set
      );

    if ($error) {
        # serious error in input parameters, no tidied output
        $self->app->abort("Perl::Minifier Error $stderr_string");
    }
    
    return $dest_string;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
