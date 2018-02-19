package Script::Toolbox::Util::Menues;

# THIS IS DEPRECATED CODE.
# DON'T USE IT.
# USE Script::Toolbox::Util::Menus

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
#$VERSION = '0.03';


# Preloaded methods go here.

#-----------------------------------------------------------------------------
# {'menueName>' =>[{label=>,value=>,jump=>,argv=>},...]}
#-----------------------------------------------------------------------------
sub new
{
	my $classname = shift;
	my $self      = {};
	bless( $self, $classname );
	$self->_init( @_ );
	return $self;
}

#-----------------------------------------------------------------------------
# {'<menueName>' =>[{label=>,value=>,jump=>,argv=>},...]}
#-----------------------------------------------------------------------------
sub _init
{
	my ($self, $newDef) = @_;

    $self->{'def'} = {};
    return  if( ref $newDef ne 'HASH' );
    $self->addMenue($newDef);
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getHead($){
    my ($self,$def) = @_;
    my $s = '';
    foreach my $k ( @{$def} ) {
        next    if( ! defined $k->{'header'} );
        $s .= sprintf "%s", $k->{'header'};
    }
    return $s ne '' ? $s : undef;
}
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getFoot($){
    my ($self,$def) = @_;
    my $s = '';
    foreach my $k ( @{$def} ) {
        next    if( ! defined $k->{'footer'} );
        $s .= sprintf "%s", $k->{'footer'};
    }
    return $s ne '' ? $s : undef;
}

#------------------------------------------------------------------------------
# ...
# {'label'=>'Call the submenue 1','jump'=>'SubMenue1'}
# SubMenue1: is the name of a previous defined menue in the same menues container
#------------------------------------------------------------------------------
sub _resolveSubmenue($){
    my ($self,$opt) = @_;

    return  if( !defined $opt->{'jump'} );
    return  if( ref \$opt->{'jump'} ne 'SCALAR' );

    my $subName = $opt->{'jump'};
    $opt->{'jump'} = \&Script::Toolbox::Util::Menues::run;
    $opt->{'argv'} = [$self,$subName];
    return;
}

#------------------------------------------------------------------------------
# [{label=>,value=>,jump=>,argv=>},...]}
#------------------------------------------------------------------------------
sub _getOpts($){
    my ($self,$def) = @_;
    my @s;
    foreach my $k ( @{$def} ) {
        next    if( ! defined $k->{'label'} );
        $self->_resolveSubmenue($k);
        push @s, $k;
    }
    return \@s;
}

#------------------------------------------------------------------------------
# <menueName>, [{label=>,value=>,jump=>,argv=>},...]}
#------------------------------------------------------------------------------
sub addMenue($){
    my ($self,$newDef) = @_;

    return  if( ref $newDef ne 'HASH' );

    foreach my $name ( keys %{$newDef} ){
        my $def                       = $newDef->{$name};
        $self->{'def'}{$name}{'head'} = $self->_getHead($def);
        $self->{'def'}{$name}{'foot'} = $self->_getFoot($def);
        $self->{'def'}{$name}{'opts'} = $self->_getOpts($def);
    }
    return;
}

#------------------------------------------------------------------------------
# <menueName>, <HeaderString>
#------------------------------------------------------------------------------
sub setHeader($$){
    my ($self,$name,$head) = @_;

    $self->{'def'}{$name}{'head'} = $head;
    return;
}


#------------------------------------------------------------------------------
# <menueName>, <HeaderString>
#------------------------------------------------------------------------------
sub setAutoHeader($){
    my ($self,$name) = @_;
    
    if( defined $name) {
        $self->{'def'}{$name}{'autohead'} = 1;
        return;
    }
    foreach my $n (keys %{$self->{'def'}} ){
        $self->{'def'}{$n}{'autohead'} = 1;
    }
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _delAutoHead($){
    my ($ah) = @_;
    delete $ah->{'autohead'} if( defined $ah->{'autohead'} );
}

#------------------------------------------------------------------------------
# <menueName>, <HeaderString>
#------------------------------------------------------------------------------
sub delAutoHeader($){
    my ($self,$name) = @_;

    if( defined $name) {
        _delAutoHead( $self->{'def'}{$name} );
        return;
    }
    foreach my $n (keys %{$self->{'def'}} ){
        _delAutoHead( $self->{'def'}{$n}  );
    }
}

#------------------------------------------------------------------------------
# <menueName>, <HeaderString>
#------------------------------------------------------------------------------
sub getHeader($){
    my ($self,$name) = @_;

    my $autoHead = $self->{'def'}{$name}{'autohead'};
    my $H;
    my $h = $self->{'def'}{$name}{'head'};
       $h = "Menue: $name"      if(!defined $h && defined $autoHead);
       $H = {'header' => $h}    if( defined $h );

    return $H;
}

#------------------------------------------------------------------------------
# <menueName>, <FooterString>
#------------------------------------------------------------------------------
sub setFooter($$){
    my ($self,$name,$foot) = @_;

    $self->{'def'}{$name}{'foot'} = $foot;
    return;
}

#------------------------------------------------------------------------------
# <menueName>, <FooterString>
#------------------------------------------------------------------------------
sub getFooter($){
    my ($self,$name) = @_;

    my $foot = $self->{'def'}{$name}{'foot'} ;
    return {'footer'=> $foot}   if(defined $foot);
    return undef;
}

#------------------------------------------------------------------------------
# <menueName>, {label=>,value=>,jump=>,argv=>}
#------------------------------------------------------------------------------
sub addOption($$){
    my ($self,$name,$opt) = @_;

    $self->{'def'}{$name}{'opts'} = []  if( ! defined $self->{'def'}{$name}{'opts'} );

    $self->_resolveSubmenue($opt);
    push @{$self->{'def'}{$name}{'opts'}}, $opt;
    return;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getParams($){
    my ($self,$name) = @_;

    my @p;
    my $s = $self->getHeader($name); push @p, $s if( defined $s );
       $s = $self->getFooter($name); push @p, $s if( defined $s );
    push @p, {'label'=>'RETURN'};
    map {
        push @p, $_;
    } @{$self->{'def'}{$name}{'opts'}};

    return \@p;
}

#------------------------------------------------------------------------------
# Validate parameters and rearrange parameters in case of internal menue call
# ( submenue call by name).
# Return 0 if parameters invalid.
#------------------------------------------------------------------------------
sub validateParams($$){
    my ($self,$name) = @_;
    return 0      if( ! defined $$self );
    if( ref $$self eq 'ARRAY' ) {
       return 0   if( ref $$self->[0] ne  'Script::Toolbox::Util::Menues' );
       $$name = $$self->[1];
       $$self = $$self->[0];
    }
    return 1      if( defined $$self->{'def'}{$$name} );
    Script::Toolbox::Util::Log("\nWARNING: Submenue $$name is not defined!");
    sleep  5;
    return 0;
}

#------------------------------------------------------------------------------
# Run the named menue as long as $cnt is true. $cnt will be decremented by each
# loop. That means if $cnt starts with 0 we have an endless loop. 
# Return the number of the last selected option.
# The option 'RETURN' will be created automaticly and has option number 0 by
# default.
#------------------------------------------------------------------------------
sub run($$){
    my ($self,$name,$cnt) = @_;

    return      if( ! validateParams(\$self,\$name) );
    $cnt = 1    if( ! defined $cnt);
    $cnt = 1    if( $cnt !~ /^[-]?\d+$/ );
    $cnt =-1    if( $cnt == 0 );
    my $o; my $m;
    while($cnt--) {
        my $p   = $self->_getParams($name);
        ($o,$m) = Script::Toolbox::Util::Menue($p);
        $self->{'def'}{$name}{'selected'}{'num'} = $o;
        $self->{'def'}{$name}{'selected'}{'opt'} = $m->[$o];
        return $o   if( $o == 0 );
    }
    return $o;
}

#------------------------------------------------------------------------------
# Return current nmber of selected option.
#------------------------------------------------------------------------------
sub currNumber($){
    my ($self,$name) = @_;
    return $self->{'def'}{$name}{'selected'}{'num'};
}

#------------------------------------------------------------------------------
# Return current label of selected option.
#------------------------------------------------------------------------------
sub currLabel($){
    my ($self,$name) = @_;
    return $self->{'def'}{$name}{'selected'}{'opt'}{'label'};
}

#------------------------------------------------------------------------------
# Return current value of selected option.
#------------------------------------------------------------------------------
sub currValue($){
    my ($self,$name) = @_;
    return $self->{'def'}{$name}{'selected'}{'opt'}{'value'};
}

#------------------------------------------------------------------------------
# Return the callback address and argv address of selected option.
#------------------------------------------------------------------------------
sub currJump($){
    my ($self,$name) = @_;

    my $call = $self->{'def'}{$name}{'selected'}{'opt'}{'jump'};
    my $args = $self->{'def'}{$name}{'selected'}{'opt'}{'argv'};
  
    return $call,$args;
}

#------------------------------------------------------------------------------
# Set a new label for current selected option. Return old label.
#------------------------------------------------------------------------------
sub setCurrLabel($$){
    my ($self,$name,$newLabel) = @_;

    my $cn = $self->currNumber($name) -1;
    my $ol = $self->{'def'}{$name}{'opts'}[$cn]{'label'};
             $self->{'def'}{$name}{'opts'}[$cn]{'label'} = $newLabel;
    return $ol;
}

#------------------------------------------------------------------------------
# Set a new value for current selected option. Return old value.
#------------------------------------------------------------------------------
sub setCurrValue($$){
    my ($self,$name,$newValue) = @_;

    my $cn = $self->currNumber($name) -1;
    my $ov = $self->{'def'}{$name}{'opts'}[$cn]{'value'};
             $self->{'def'}{$name}{'opts'}[$cn]{'value'} = $newValue;
    return $ov;
}

#------------------------------------------------------------------------------
# Set new callback address und argv for the current selected option.
#------------------------------------------------------------------------------
sub setCurrJump($$$){
    my ($self,$name,$callBack,$argv) = @_;

    my $cn = $self->currNumber($name) -1;
    $self->{'def'}{$name}{'opts'}[$cn]{'jump'} = $callBack;
    $self->{'def'}{$name}{'opts'}[$cn]{'argv'} = $argv;
    return $callBack,$argv;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _invalidParam($$$$$){
    my ($self,$name,$pattern,$search,$return) = @_;
    return  1  if( !defined $pattern );
    return  1  if( !defined $search  );
    return  1  if( !defined $return  );
    return  1  if( !defined $self->{'def'}{$name}{'opts'});
    return  1  if( $search !~ /(number|value|label)/ );
    return  1  if( $return !~ /(number|value|label)/ );
    return  0;
}

#------------------------------------------------------------------------------
# Search the labels array for $pattern matching in $search. If matching return
# value of type return.
# $pattern='[Mm]ax' $search='value' $return='label'
# => returns all labels where value column matching Max or max.
# search: /(label,number,value)/
# return: /(label,number,value)/
#------------------------------------------------------------------------------
sub getMatching($$$$){
    my ($self,$name,$pattern,$search,$return) = @_;
    return '' if( _invalidParam($self,$name,$pattern,$search,$return));

    my $L = $self->{'def'}{$name}{'opts'};
    my @R;
    my $i=1;
    foreach my $l ( @{$L} ){
        if( $search eq 'number' ){
            push @R, $l->{$return}  if( $i =~ /$pattern/);
            $i++;
        }else{
            next    if( !defined $l->{$search} );
            next    if( $l->{$search} !~ /$pattern/ );
            push @R, $l->{$return};
        }
    }
    return \@R;
}


1;
__END__

=head1 NAME

Script::Toolbox::Util::Menues - see documentaion of Script::Toolbox

=cut

