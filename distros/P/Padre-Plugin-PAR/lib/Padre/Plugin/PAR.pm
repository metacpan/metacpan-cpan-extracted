package Padre::Plugin::PAR;
use strict;
use warnings;
use base 'Padre::Plugin';

our $VERSION = '0.06';

use Padre::Wx;
use Padre::Util   ('_T');

sub require_modules {
    require File::Temp;
}

=head1 NAME

Padre::Plugin::PAR - PAR generation from Padre

=head1 SYNOPIS

This is an experimental version of the plugin using the experimental
plugin interface of Padre 0.24.

After installation there should be a menu item I<Padre - PAR - Stand Alone>

Clicking on that menu item while a .pl file is in view will generate a stand alone
executable with .exe extension next to the .pl file.

If you are currently editing an unsaved buffer, it will be saved to a temporary
file for you.

=cut

sub padre_interfaces {
  'Padre::Plugin'         => 0.43,
  'Padre::Current'        => 0.43,
}

sub menu_plugins_simple {
    my $self = shift;
    return 'PAR' => [
        _T('Create Standalone Exe') => \&on_stand_alone,
        _T('About') => sub { $self->about },
    ];
}

sub about {
    my $self = shift;

    # Generate the About dialog
    my $about = Wx::AboutDialogInfo->new;
    $about->SetName("PAR Plugin");
    $about->SetDescription( <<"END_MESSAGE" );
This is an experimental plugin for Padre to allow
you to generate standalone executables from your Perl
programs using PAR, the Perl ARchive Toolkit.
END_MESSAGE

    # Show the About dialog
    Wx::AboutBox( $about );

    return;
}

sub on_stand_alone {
    my ($mw, $event) = @_;

    require_modules();

    #print "Stand alone called\n";
    # get name of the current file, if it is a pl file create the corresponding .exe

    my $doc = $mw->current->document;

    my $filename = $doc->filename;
    my $tmpfh;
    my $cleanup = sub { unlink $filename if $tmpfh };
    local $SIG{INT} = $cleanup;
    local $SIG{QUIT} = $cleanup;

    if (not $filename) {
        ($filename, $tmpfh) = _to_temp_file($doc);
    }

    if ($filename !~ /\.pl$/i) {
        Wx::MessageBox( _T("Currently we only support exe generation from .pl files"), _T("Cannot create"), Wx::wxOK|Wx::wxCENTRE, $mw );
        return;
    }
    (my $out = $filename) =~ s/pl$/exe/i;
    my $ret = system("pp", $filename, "-o", $out);
    if ($ret) {
       Wx::MessageBox( sprintf(_T("Error generating '%s': %s"), $out, $!) , _T("Failed"), Wx::wxOK|Wx::wxCENTRE, $mw );
    } else {
       Wx::MessageBox( sprintf(_T("%s generated"), $out), _T("Done"), Wx::wxOK|Wx::wxCENTRE, $mw );
    }

    if ($tmpfh) {
      unlink($filename);
    }

    return;
}

sub _to_temp_file {
    my $doc = shift;

    my $text = $doc->text_get();

    my ($fh, $tempfile) = File::Temp::tempfile(
      "padre_standalone_XXXXXX",
      UNLINK => 1,
      TMPDIR => File::Spec->tmpdir(),
      SUFFIX => '.pl',
    );
    local $| = 1;
    print $fh $text;
    return($tempfile, $fh);
}

1;

__END__

=head1 INSTALLATION

You can install this module like any other Perl module and it will
become available in your Padre editor. However, you can also
choose to install it into your user's Padre configuration directory only.
The necessary steps are outlined in the C<README> file in this distribution.
Essentially, you do C<perl Build.PL> and C<./Build installplugin>.

=head1 COPYRIGHT

(c) 2008 Gabor Szabo http://www.szabgab.com/

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=head1 WARRANTY

There is no warranty whatsoever.
If you lose data or your hair because of this program,
that's your problem.

=cut
