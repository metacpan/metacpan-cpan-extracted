#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Abort;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Abort - Abort the application at anytime with optional message and stacktrace.

=head1 SYNOPSIS
        
    $self->app->abort("error message");

    $self->app->abort("error title", "error message");

=head1 DESCRIPTION

Nile::Abort - Abort the application at anytime with optional message and stacktrace.

=cut

use Nile::Base;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub abort {

    my ($self) = shift;

    my ($title, $msg, $trace, @trace, $out);

    #my ($callpackage, $callfile, $callline, $subroutine, $hasargs, $wantarray, $evaltext, $is_require) = caller;

    if (@_ == 2) {
        ($title, $msg) = @_;
    }
    else {
        ($msg) = @_;
        $title = "Application Error";
    }
    
    #@trace = reverse split(/\n/, Carp::longmess());
    #$trace = join ("<br>\n", @trace);
    #$trace = Carp::longmess();

=cuts
my $out = <<HTML;
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Application Error</title>
</head>
<body style="background: #ffffff;" >

<div align="center" style="margin-top: 100px;">
    <table cellpadding="0" cellspacing="0" style="width: 650px; border: 2px #e5e5e5 solid; border-collapse: collapse;">
      <tr><td>
            <table border="0" cellpadding="8" cellspacing="0" style="border-collapse: collapse" width="100%">
              <tr><td style="text-align: center; background: #e5e5e5;"><b>$title</b></td></tr>
              <tr><td style="background: #f3f3f3;">$msg</td></tr>
              <tr><td style="background: #f9f9f9;">$trace</td></tr>
            </table>
        </td>
      </tr>
    </table>
</div>
</body>
</html>
HTML
=cut
    
    $out = "";
    #$out .= "$title\n\n";
    $out .= "$msg\n\n";
    #$out .= "$trace\n\n";

    die $out;
    #if ($self->app->db->connected) {$self->app->db->disconnect();}
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
