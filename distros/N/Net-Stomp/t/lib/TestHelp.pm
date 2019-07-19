use strict;
use warnings;
BEGIN {$ENV{TAP_LOG_ORIGIN}=1; $ENV{TAP_LOG_SHOW_USAGE}=0 }
use Log::Any::Adapter TAP => ( filter => 'debug' );

{package TestHelp;
use strict;
use warnings;
BEGIN { $INC{'IO/Select.pm'}=__FILE__ }
use Net::Stomp;
use Test::NiceDump ();
use Test::Deep ();

sub mkstomp {
    return Net::Stomp->new({
        hosts => [ {hostname=>'localhost',port=>61613} ],
        connect_delay => 0,
        @_,
    })
}

sub mkstomp_testsocket {
    my $fh = TestHelp::Socket->new({
        connected=>1,
        to_read=>'',
    });
    no warnings 'redefine';
    local *Net::Stomp::_get_socket = sub { return $fh };
    my $s = mkstomp(@_);
    return ($s,$fh);
}

sub cmp {
    my ($got,$expected,$message) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::Deep::cmp_deeply(
        $got, $expected, $message
    ) or Test::NiceDump::nice_explain($got,$expected);
}

sub import {
    my $caller = caller;
    eval "package $caller; strict->import; warnings->import; use Test::More; use Test::Deep '!cmp_deeply';1;" or die $@;
    no strict 'refs';
    *{"${caller}::mkstomp"}=\&mkstomp;
    *{"${caller}::mkstomp_testsocket"}=\&mkstomp_testsocket;
    *{"${caller}::cmp_deeply"}=\&cmp;
    return;
}
}

{package TestHelp::Socket;
use strict;
use warnings;

sub new {
    bless $_[1],$_[0];
}
sub connected { return $_[0]->{connected} }
sub close { $_[0]->{connected} = undef; }
sub syswrite {
    my ($self,$string) = @_;
    my $ret;
    if (ref($self->{written})) {
        return $self->{written}->($string);
    }
    else {
        $self->{written} .= $string;
        return length($string);
    }
}

sub sysread {
    my ($self,$dest,$length,$offset) = @_;

    my $string = ref($self->{to_read})?($self->{to_read}->()):($self->{to_read});
    return if not defined $string;
    my $ret = substr($string,0,$length,'');
    substr($_[1],$offset) = $ret;
    return length $ret;
}
}

{package IO::Select;
use strict;
use warnings;

sub new { bless {can_read=>1},$_[0] }

sub add { $_[0]->{socket}=$_[1] }
sub remove { delete $_[0]->{socket} }

sub can_read {
    my ($self) = @_;
    return unless $self->{socket};
    my $can_read = ref($self->{can_read})?($self->{can_read}->()):($self->{can_read});
    return $can_read;
}
}

1;
