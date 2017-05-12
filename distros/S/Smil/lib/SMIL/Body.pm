package SMIL::Body;

$VERSION = "0.898";

use SMIL::XMLContainer;
use SMIL::Par;
use SMIL::Seq;
use SMIL::MediaFactory;
use SMIL::Switch;
use SMIL::Code;

@ISA = qw( SMIL::XMLContainer ); 

$SEQ = "seq";
$PAR = "par";

use Carp;

my $timelineStack = "timelineStack";
my $mediaStack = "mediaStack";
my $counter = "counter";
my $timeline = "timeline";
my $href = 'href';
my $anchors = 'anchors';
my $switch = 'switch';
my $medias = 'medias';
my $par_bug = 1;

sub init {
    my $self = shift;
    $self->SUPER::init( "body" );
    $self->initTimeline() unless $par_bug;
}

sub initTimeline {
    my $self = shift;
    my $array_ref = [];
    $self->{$timelineStack} = $array_ref;
    
    # Removed to fix first Par bug
    if( !$par_bug ) {
	my $par = new SMIL::Par;
	push @{$self->{$timelineStack}}, $par;
	$self->setTagContents( $timeline => $par );
    }
    else {
	my $tag = shift;
	push @{$self->{$timelineStack}}, $tag;
	$self->setTagContents( $timeline => $tag );
    }
}

sub startSequence {
    my $self = shift;
    my $seq = new SMIL::Seq( @_ );
    if( !$par_bug || @{$self->{$timelineStack}} ) {
	${$self->{$timelineStack}}[ -1 ]->setTagContents( $self->{$counter}++ => $seq );	
        push @{$self->{$timelineStack}}, $seq;
    }
    else {
	$self->initTimeline( $seq );
    }
    croak "Timeline not there\n" unless @{$self->{$timelineStack}};
}

sub startParallel {
    my $self = shift;
    my $par = new SMIL::Par( @_ );
    if( !par_bug || @{$self->{$timelineStack}} ) {
	${$self->{$timelineStack}}[ -1 ]->setTagContents( $self->{$counter}++ => $par );	
        push @{$self->{$timelineStack}}, $par;
    } 
    else { 
        $self->initTimeline( $par );
    }
    
    if( 0 ) {
	${$self->{$timelineStack}}[ -1 ]->setTagContents( $self->{$counter}++ => $par );
        push @{$self->{$timelineStack}}, $par;
    }

    croak "Timeline not there \n" unless @{$self->{$timelineStack}};
}

sub endParallel {
    my $self = shift;
    my $top = pop @{$self->{$timelineStack}};
    croak "Bad timeline: make sure that start and end functions match.\n" 
	if $check_errors && ( !$top || $top->getTag() ne $PAR );
}

sub endSequence {
    my $self = shift;
    my $top = pop @{$self->{$timelineStack}};;
    croak "Bad timeline: make sure that add and end functions match.\n" 
	if $check_errors && ( !$top || $top->getTag() ne $SEQ );
}

# Strictly for debugging
sub printTimelineStack {
    foreach $item ( @{$self->{$timelineStack}} ) {
	print "$item\n";
    }
}

sub addMedia {
    my $self = shift;
    my %hash = @_;
				
    $self->initTimeline( new SMIL::Par ) 
								unless( $self->{$timelineStack} && @{$self->{$timelineStack}} );
    croak "Need to call startParallel or startSequence before adding media\n" 
								if !$check_errors && !@{$self->{$timelineStack}};
				
    my $timeline_head = ${$self->{$timelineStack}}[ -1 ];
    my $media = &getMediaObject( @_ );     
    $timeline_head->setTagContents( $self->{$counter}++ => $media );
}

sub addCode {
    my $self = shift;
    my $code = shift;
    
    if( $self->{$timelineStack} && @{$self->{$timelineStack}} ) {
	my $timeline_head = ${$self->{$timelineStack}}[ -1 ];
        my $media = new SMIL::Code( $code );     
        $timeline_head->setTagContents( $self->{$counter}++ => $media );
    } 
    else {     
        $self->initTimeline( new SMIL::Code( $code ) );
    }
}


sub addSwitchedMedia {
    my $self = shift;
    my %hash = @_;
    
    # Extract the switch attribute
    my $switch_attribute = $hash{ $switch };
    my $media = $hash{ $medias };
 
    $self->initTimeline( new SMIL::Par ) 
								unless( $self->{$timelineStack} && @{$self->{$timelineStack}} );
    croak "Need to call startParallel or startSequence before adding media\n" 
								if !$check_errors && !@{$self->{$timelineStack}};
				
    my $switch_obj = new SMIL::Switch( $switch_attribute, $media );
    my $timeline_head = ${$self->{$timelineStack}}[ -1 ];
    $timeline_head->setTagContents( $self->{$counter}++ => $switch_obj );

}


