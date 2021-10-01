package TestEnv;

use strict;
use warnings;

use Cwd qw(getcwd);
use File::Temp qw(tempdir);
use File::Copy;

sub new {
    my $class = shift;

    bless {}, $class;
}

sub i18n_tempdir { $_[0]->{i18ntempdir} }

sub setup_i18n_tempdir {
    my ($self, $lang_name, $lang_origin_prefix) = @_;

    $self->free_i18n_tempdir if $self->i18n_tempdir;

    $self->{cwd}         = &getcwd;
    $self->{i18ntempdir} = tempdir(CLEANUP => 1);

    foreach my $dir (qw(templates lib lib/Lexemes lib/Lexemes/I18N)) {
        mkdir $self->i18n_tempdir . "/$dir";
    }

    opendir(my $th, "$FindBin::Bin/templates/");
    while (my $template = readdir($th)) {
        next if $template eq '.' or $template eq '..';
        copy(
            "$FindBin::Bin/templates/$template",
            $self->i18n_tempdir . "/templates/$template"
        ) or die $!;
    }
    close $th;

    copy(
        "$FindBin::Bin/lib/Lexemes/I18N.pm",
        $self->i18n_tempdir . "/lib/Lexemes/I18N.pm"
    ) or die $!;

    if (defined $lang_name) {
        copy(
            "$FindBin::Bin/lib/Lexemes/I18N/$lang_name.pm.$lang_origin_prefix",
            $self->i18n_tempdir . "/lib/Lexemes/I18N/$lang_name.pm"
        ) or die $!;
    }

    chdir $self->i18n_tempdir;
    $ENV{MOJO_HOME} = $self->i18n_tempdir;
    unshift @INC, $self->i18n_tempdir . "/lib/";
}

sub free_i18n_tempdir {
    my $self = shift;
    die 'Not setuped' unless defined $self->{i18ntempdir};
    my $lib = $self->i18n_tempdir . "/lib/";

    delete $self->{i18ntempdir};
    chdir delete $self->{cwd};
    delete $ENV{MOJO_HOME};
    @INC = grep { $_ ne $lib } @INC;
}

1;
