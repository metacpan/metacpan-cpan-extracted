package Net::LiveJournal::Entry;
use strict;
use warnings;
use Carp qw(croak);

sub new {
    my ($class, %opts) = @_;
    my $self = bless {}, $class;

    $self->{body}       = delete $opts{body}       || delete $opts{event};
    $self->{subject}    = delete $opts{subject}    || "";
    $self->{security}   = delete $opts{security}   || "public";
    $self->{allowmask}  = delete $opts{allowmask}  || 0;
    $self->{usejournal} = delete $opts{usejournal} || delete $opts{community} || delete $opts{journal};

    my @now = localtime();
    $self->{year} = $now[5]+1900;
    $self->{mon} = $now[4]+1;
    $self->{day} = $now[3];
    $self->{hour} = $now[2];
    $self->{min} = $now[1];

    croak("Unknown options: " . join(", ", %opts)) if %opts;
    return $self;
}

sub year       { $_[0]{year}   }
sub month      { $_[0]{mon}    }
sub mon        { $_[0]{mon}    }
sub day        { $_[0]{day}    }
sub hour       { $_[0]{hour}   }
sub min        { $_[0]{min}    }
sub minute     { $_[0]{min}    }

sub body       { $_[0]{body}      }
sub subject    { $_[0]{subject}   }
sub allowmask  { $_[0]{allowmask} }
sub security   { $_[0]{security}  }

sub usejournal { $_[0]{usejournal} }
sub journal    { $_[0]{usejournal} }

1;
