package Tcl::Tk::Widget::Balloon;

use strict;
use vars qw/@ISA/;
@ISA = qw(Tcl::Tk::Widget);

sub attach {
    print STDERR "bal-attach:[@_];\n";
    my $bw = shift;
    my $w = shift;
    my $int = $bw->interp;
    my %args=@_;
    my $msg = delete $args{-msg};
    $msg ||= delete $args{-balloonmsg};
    $$msg = '*****';
    $int->call($bw->path.'.f2.message','configure',-textvariable=>$msg);
    delete $args{$_} for qw(-postcommand -motioncommand -balloonposition); # TODO!
    for (qw(-initwait)) {
	if (exists $args{$_}) {
	    $bw->configure($_,delete $args{$_});
	}
    }
    $int->call($bw,'bind',$w,%args);
}
sub detach {
    my $bw = shift;
    my $w = shift;
    my $int = $bw->interp;
    $int->call($bw,'unbind',$w,@_);
}

sub DESTROY {}			# do not let AUTOLOAD catch this method

sub AUTOLOAD {
    print STDERR "<<@_>>\n" if $Tcl::Tk::DEBUG > 2;
    $Tcl::Tk::Widget::AUTOLOAD = $Tcl::Tk::Widget::Balloon::AUTOLOAD;
    return &Tcl::Tk::Widget::AUTOLOAD;
}

1;

