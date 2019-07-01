package Tcl::pTk::MainWindow;

our ($VERSION) = ('1.02');

use Tcl::pTk::Toplevel;

@Tcl::pTk::MainWindow::ISA = (qw/ Tcl::pTk::Toplevel/);


sub DESTROY {}			# do not let AUTOLOAD catch this method

sub AUTOLOAD {
    $Tcl::pTk::Widget::AUTOLOAD = $Tcl::pTk::MainWindow::AUTOLOAD;
    return &Tcl::pTk::Widget::AUTOLOAD;
}

sub path {'.'}

sub new {
    my $self = shift;
        # Configure the just created mainwindow, if any args
        $self->configure(@_) if (@_);
        
        return $self;

}

# provide -title option for 'configure', for perlTk compatibility
sub configure {
    my $self = shift;
    if(@_ == 1){ # if calling configure on an option (e.g. $widget->configure(-title))
                 #   just call our parent
         #print STDERR "Calling configure on ".join(", ", @_)."\n";
        my $temp = 1;
        return $self->SUPER::configure(@_);
    }
    my %args = @_;
    if (exists $args{'-title'}) {
	$self->interp->invoke('wm','title',$self->path,$args{'-title'});
	delete $args{'-title'};
    }
    if (scalar keys %args > 0) {
	# following line should call configure on base class, Tcl::pTk::Widget
	# for some reason, AUTOLOAD sub receives 'SUPER::' within AUTOLOAD
	$self->SUPER::configure(%args);
    }
}
sub cget {
    my $self = shift;
    my $opt = shift;
    if ($opt eq '-title') {
	return $self->interp->invoke('wm','title',$self->path);
    }
    return $self->SUPER::cget($opt);
}


1;

