package Proc::Safetynet::Program::Storage::TextFile;
use strict;
use warnings;
use Carp;
use JSON::XS;

use Moose;

extends 'Proc::Safetynet::Program::Storage::Memory';

# NOTE: uses implementation inheritance

has 'file' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);


sub commit {
    my $self = shift;
    {
        my ($filename) = ($self->file() =~ /^(.*)$/);
        open my $fh, ">$filename"
            or croak "unable to open storage file: $filename: $!";
        
        my @out = ();
        my $hr = $self->_children();
        foreach my $k (sort keys %$hr) {
            my $p = $hr->{$k};
            my $oh = { };
            foreach my $ok (keys %$p) {
                $oh->{$ok} = $p->$ok();
            }
            push @out, $oh;
        }
        print $fh JSON::XS->new->utf8->pretty->encode( \@out );
        close $fh;
    }
}


sub reload {
    my $self = shift;
    {
        $self->_children({});
        my $filename = $self->file();
        open my $fh, $filename
            or croak "unable to open programs storage file: ($filename): $!";
        # FIXME: capture errors
        my $indata = join '', <$fh>;
        close $fh;
        my $in;
        eval {
            $in = decode_json( $indata );
        };
        if ($@) {
            croak "unable to decode programs storage file ($filename): $@";
        }
        foreach my $d (@$in) {
            my $i = Proc::Safetynet::Program->new( $d );
            $self->_children->{$i->name()} = $i;
        }
    }
}


1;

__END__
