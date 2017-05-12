package Runops::Recorder::Viewer::Diff;

use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Term::ReadKey;

use Runops::Recorder::Reader;

use accessors::ro qw(
    enter_subs
    lines 
    num_readers
    paths 
    readers 
    reader_id 
    sources
);

sub new {
    my ($pkg, @paths) = @_;
    
    my $self = bless {    
    }, $pkg;
    
    my @readers = map { Runops::Recorder::Reader->new($_, { handler => $self }) } @paths;
    $self->{reader_id} = { map { $readers[$_] => $_ } 0..(@readers - 1) };
    $self->{readers} = { map { $_ => $readers[$_] } 0..(@readers - 1) };
    $self->{num_readers} = @paths;
    $self->{sources} = [];
    return $self;
}

sub reset {
    my $self = shift;
    
    $self->{paths} = [];
    $self->{lines} = [];
    $self->{enter_subs} = [];
}

sub on_switch_file {
    my ($self, $id, $path, $reader) = @_;
    
    $self->paths->[$self->reader_id->{$reader}] = $path;
    
    open my $in, "<", $path or die $!;
    my @src = <$in>;
    $self->sources->[$self->reader_id->{$reader}] = \@src;
    close $in;
}

sub on_next_statement {
    my ($self, $line, $reader) = @_;
    
    my $data = $self->sources->[$self->reader_id->{$reader}]->[$line - 1];
    chomp $data if $data;

    $self->lines->[$self->reader_id->{$reader}] = [$line, $data];
}

sub on_enter_sub {
    my ($self, $id, $subname, $reader) = @_;
    $self->enter_subs->[$self->reader_id->{$reader}] = $subname;    
}

sub display {
    my $self = shift;
    
    my ($cols) = Term::ReadKey::GetTerminalSize(*STDOUT);
    my $readers = $self->num_readers;
    my $cols_per_reader = int($cols / $readers);

    my $printed;
    if (@{$self->paths}) {
        for (0..($readers - 1)) {
            my $width = $cols_per_reader - 4;
            if ($self->paths->[$_]) {
                $printed += printf "* %-${width}s  ", substr($self->paths->[$_], 0, $cols_per_reader - 2);
            }
            else {
                $printed += print " " x $cols_per_reader;
            }
        }
    }

    if (@{$self->lines}) {
        for (0..($readers - 1)) {
            my $width = $cols_per_reader - 8;
            if ($self->lines->[$_]) {
                my ($line_no, $source) = @{$self->lines->[$_]};
                $source //= "";
                $printed += printf "% 4d: %-${width}s  ", $line_no, substr($source, 0, $width);
            }
            else {
                $printed += print " " x $cols_per_reader;
            }
        }
    }

    if (@{$self->enter_subs}) {
        for (0..($readers - 1)) {
            my $width = $cols_per_reader - 6;
            if ($self->enter_subs->[$_]) {
                printf "sub % -${width}s ", substr($self->enter_subs->[$_], 0, $width) . " {";
            }
            else {
                print " " x $cols_per_reader;
            }
        }
    }    

    print "\n" if $printed;
}

sub run {
    my $self = shift;

    my @readers = values %{$self->readers};
    
    for (;;) {
        $self->reset;

        my $has_more = 0;
        for my $r (@readers) {
            $has_more |= 1 if $r->read_next;
        }
        
        last unless $has_more;
        
        $self->display();
    }
    
    print "Done\n";
}

1;