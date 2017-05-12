use strict; use warnings;
package Module::Manifest::Skip;
our $VERSION = '0.23';

use Moo;

has text => (
    is => 'ro',
    builder => 'text__',
    lazy => 1,
);

has old_text => (
    is => 'ro',
    default => sub {
        my $self = shift;
        return $self->read_file('MANIFEST.SKIP', 1);
    },
);

sub import {
    my ($package, $command) = @_;
    if ($command and $command eq 'create') {
        my $text = $package->new->text;
        open MS, '>', 'MANIFEST.SKIP'
            or die "Can't open MANIFEST.SKIP for output:\n$!";
        print MS $text;
        close MS;
        exit;
    }
    else {
        goto &Moo::import;
    }
}

sub add {
    my $self = shift;
    my $addition = shift or return;
    chomp $addition;
    if (not $self->{add_occurred}++) {
        $self->{text} =~ s/\n+\z/\n\n/;
    }
    $self->{text} .= $addition . "\n";
}

sub remove {
    my $self = shift;
    my $exclude = shift or return;
    $self->{text} =~ s/^(\Q$exclude\E)$/# $1/mg;
}

sub text__ {
    my $self = shift;
    my $old = $self->old_text;
    my $text = ($old =~ /\A(\S.*?\n\n)/s) ? $1 : '';
    chomp $text;
    $text .= $self->skip_template;
    local $self->{text} = $text;
    $self->reduce;
    return $self->{text};
}

sub reduce {
    my $self = shift;
    while ($self->{text} =~ s/^- (.*)$/* $1/m) {
        $self->remove($1);
    }
    $self->{text} =~ s/^\* /- /mg;
}

sub skip_template {
    my $self = shift;
    my $path = $INC{'Module/Manifest/Skip.pm'} or die;
    if (-e 'lib/Module/Manifest/Skip.pm') {
        return $self->read_file('share/MANIFEST.SKIP');
    }
    elsif ($path =~ s!(\S.*?)[\\/]?\blib\b.*!$1! and -e "$path/share") {
        return $self->read_file("$path/share/MANIFEST.SKIP");
    }
    else {
        require File::ShareDir;
        require File::Spec;
        my $dir = File::ShareDir::dist_dir('Module-Manifest-Skip');
        my $file = File::Spec->catfile($dir, 'MANIFEST.SKIP');
        die "Can't find MANIFEST.SKIP share file for Module::Manifest::Skip"
            unless $dir and -f $file and -r $file;
        return $self->read_file($file);
    }
}

sub read_file {
    my ($self, $file, $ignore) = @_;
    open FILE, $file or
        $ignore and return '' or
        die "Can't open '$file' for input:\n$!";
    my $text = do { local $/; <FILE> };
    close FILE;
    $text =~ s/\r//g;
    return $text;
}

1;
