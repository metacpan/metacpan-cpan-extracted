package Common;
use strict;
use warnings;

use Test::Unit::Lite;
use Encode;
use Spreadsheet::Write;

use base qw(Test::Unit::TestCase);

###############################################################################

sub tear_down {
    my $self=shift;

    unlink $self->{'tempfile'} if $self->{'tempfile'} && -f $self->{'tempfile'};
}

###############################################################################

sub spreadsheet_test {
    my ($self,$format,$refdata)=@_;

    my $filename=$self->{'tempfile'}='deleteme.tmp';

    my $sp=new Spreadsheet::Write(
        file        => $filename,
        format      => $format,
    );

    $sp->addrow({ style => 'header', content => [
        'Column1',
        'Column#2',
        'Column 3',
        'Column  4',
    ]});

    $sp->freeze(1,0);

    for(my $i=1; $i<3; ++$i) {
        $sp->addrow(
            { style => 'ntext', content => $i },
            "Cell #2/$i",
            { font_style => 'italic', content => [ "C.3/$i", "C.4/$i/\x{263A}" ] }
        );
    }

    $sp->close;

    $self->assert(-f $filename,
        "Expected $filename to exist");

    my $fd=IO::File->new($filename,'r');
    $fd->binmode;

    $self->assert(!!$fd,
        "Expected to be able to read $filename: $!");

    my $blob=join('',$fd->getlines);

    $fd->close;

    if(defined $refdata) {
        my $refblob=$refdata;

        if(ref $refdata) {
            local $/=undef;
            binmode $refdata;
            my $pos=tell $refdata, 0;
            $refblob=<$refdata>;
            seek $refdata,$pos,0;
        }

        if($blob ne $refblob) {
            print STDERR "====== Expected:\n".($refblob//'<undef>')."======\n";
            print STDERR "====== Expected:\n".($blob//'<undef>')."======\n";
        }

        $self->assert($blob eq $refblob,
            "Spreadsheet data does not match reference for '$format'");
    }
}

###############################################################################

sub check_package ($$) {
    my ($self,$pkg)=@_;

    eval "use $pkg";

    if($@) {
        warn "Package '$pkg' is not available\n";
        return 0;
    }

    return 1;
}

1;
