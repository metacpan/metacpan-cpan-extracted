package Real::Handy;
our $VERSION = '0.24';
my $warnings = 
  "\x54\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x15"
^ "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00";

sub clean_namespace;
my %clean_namespace;
my @autouse;
my %autouse;
my $utf8 = 0x00800000;
set_autouse( __PACKAGE__ . '=clean_namespace' );
sub set_utf8 { $utf8 = $_[0] ? 0x00800000 : 0 };
our $SKIP_CONFIG;
1 if $DB::single;
sub import{
    my $self = shift;
    my $caller = caller;
    my @caller = caller;
    do {
	my $fixpackage = $caller;
	if ( $fixpackage ne 'main' ){
	    $fixpackage=~s/::/\//g;
	    $fixpackage=~s/\.pm|\z/.pm/;
	    $INC{ $fixpackage } = $caller[1];
	}
    };
    
    $SKIP_CONFIG || do {
	$SKIP_CONFIG = 1;
	_require_config(@_);
	1;
    };
    $self->customize_module( $caller, \@_ );
    if ( $autouse{ $caller } ){
        # delete ${ $caller . "::" }{AUTOLOAD};
    }
    for my $module ( @autouse ) {
        my $state = $autouse{$module};
        if ( $state->{var} ) {
            for ( @{ $state->{var} } ) {
                my $sym     = substr($_,0,1);
                my $symname = $module . "::" . substr($_,1);
                my $ref     = $sym eq '%' ? \%{$symname} : undef;
                *{ $caller . "::" . substr($_,1) } = $ref;
            }
        }
        if ( $module eq $caller ) {    # Fix: remain own methods untouched
            next;
        }
        if ( $state->{sub} ) {
            for ( @{ $state->{sub} } ) {
		*{ $caller . "::" . $_ } = \&{ $module . "::" . $_ };
		$clean_namespace{$caller}{$_} = 1;
            }
        }
    }
    if ( $] >= 5.016){
	require feature;
	@_ = ();
	@_ = qw(feature say switch);
	goto &feature::import;
    }
}
sub bn{
    my $dd = shift;
    my $dev = shift;
    my $inode = shift;
    opendir my $f, $dd or die "Can't open dd";
    while( my $g = readdir $f ){
        my $stat = [ lstat "$dd/$g" ];
        next if $stat->[1] != $inode;
        next if $stat->[0] != $dev;
        next if $g eq '.';
        next if $g eq '..';
        return "$dd/$g" if $dd ne '/';
        return "/$g";
    }
    return;
}
sub _croak{ require Carp ; Carp->import; goto &croak; };
sub der{
    my $dd = shift;
    my $limit = shift // 16;
    _croak "not a directory" unless -d $dd;
    _croak "limit exceed" unless $limit;
    my @st = lstat $dd;
    my @rt = lstat '/';
    return '/' if $st[0] == $rt[0] && $st[1] == $rt[1];
    my @limit = split '/', $dd;
    my $before = der( $dd . '/' . '..' );
    return bn( $before, $st[0], $st[1] );
}


sub inc_remove{
    @INC = grep $_[0] ne $_, @INC;
    @INC = grep $_[1] ne $_, @INC if $_[1];
}

sub _require_config{
    # set my @INC
    my $workspace;
    my $ourdir = __FILE__;
    $ourdir=~s/\/[^\/]+\/*\z// for 1..2; 
    $ourabs = der( $ourdir );
    if ( $ourabs ){
	if ( -f "$ourabs/handy.pl" ){
	    if ( $ourabs=~s#/lib\z##  ){
		inc_remove( $ourdir );
		set_workspace( $ourabs );
		return;
	    }
	}
    }
    my @PWD;
    if   ( @_ ) {
	push @PWD, @_;
    };
    for  ( map "$_", grep $_, $a = $ENV{'DOCUMENT_ROOT'} ){
	    last unless $_;
	    s#\w+/?\z##;
	    push @PWD, $_;
    };
    local($a,$b);
    for ( grep $_, $b = $ENV{PWD}, @PWD, $0, $a = $ENV{project} ){
        if (m#(/home/sites/[-\.\w]+|/home/\w+)#){
	    my $candidate =  substr $_, 0, $+[0];
	    if ( -f "$candidate/config/site.pl" ){
                $workspace = $candidate ;
                last ;
            }
        }
    }
    if ( !$workspace ){
        warn "Can't load proper config ( ENV{project} = '$ENV{project}'";
        return;
    }
    set_workspace( $workspace );
}

sub set_workspace{
    my $location = shift;
    $location = shift if UNIVERSAL::isa( $location, 'Real::Handy' );
    return unless -d $location;
    for ( $Real::Handy::Workname = $Real::Handy::Workspace = $location){
	s/\/+\z//;
	s/.*\///;
    };
    my $l = "$location/lib";
    if ( ref $INC[0] ){
	splice @INC, 1,0,($l) if -d $l;
    }
    else {
	unshift @INC, $l if -d $l;
    }
    my ( $c ) = grep -f -s $_, "$location/lib/handy.pl", "$location/config/site.pl";
    require $c if -f $c && -s $c;
};


sub customize_module{
    my $self = shift;
    my $caller = shift;
    # strict refs, subs, vars, utf8
    $^H |= ( 0x00000002 | 0x00000200 | 0x00000400 | $utf8 );
    ${^WARNING_BITS} ^= ${^WARNING_BITS} ^ $warnings;
    *{ $caller . '::CLASS' }           = sub () { $caller; } unless exists &{  $caller . '::CLASS' };
	$^H{ $_ } = 1 for qw/feature_say feature_switch feature_state/;
}
my %cleanup_autoload;
sub cleanup_autoload{
    my $s = $cleanup_autoload{ $_[1] };
    $s->() if $s;
    undef;
}
unshift @INC, \&cleanup_autoload;
sub set_autoload {
    my ( $module ) = @_;


    my $require      = "require $module; ";

    s/::/\//g for (my $pm = $module . ".pm");
    my $cleanup = sub { 
        delete ${ $module . "::" }{AUTOLOAD};
        delete $cleanup_autoload{ $pm };
#        print STDERR "Cleanup $module<=>$pm\n";
    };
    $cleanup_autoload{ $pm } = $cleanup;

    if ( !$INC{$pm} || $INC{$pm} eq 'Stub' ) {
        *{ $module . "::AUTOLOAD" } = sub {
            our $AUTOLOAD;
            return if $AUTOLOAD =~ m/\bDESTROY\z/;
            my $autoload = $AUTOLOAD;
            {
                delete ${ $module . "::" }{AUTOLOAD};
                delete $cleanup_autoload{ $pm };
                return if caller() eq $module;
                delete $INC{$pm} if ($INC{$pm}||'') eq 'Stub';
                eval $require;
                die $@ if $@;
            };
            goto &$autoload if exists &$autoload;
            if ( UNIVERSAL::isa( $_[0], $module ) ) {
                my $sub;
                s/.*::// for my $subname = $autoload;
                $sub = UNIVERSAL::can( $_[0], $subname );
                goto &$sub if $sub;
                $sub = UNIVERSAL::can( $_[0], 'AUTOLOAD' );
                if ($sub) {
                    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
                    return $_[0]->$subname( @_[ 1 .. $#_ ] );
                }
            }
            require Carp;
            local $Carp::CarpLevel = 1;
            Carp::croak("Undefined procedure $autoload called");
        };
    }
}
sub set_autouse{
    while (@_) {
	if ($_[0]=~m/\n/){
		push @_, split " ", $_[0];
		next;
	}
        my ( $module, $param ) = split "=", $_[0], 2;

        my $state = $autouse{ $module };
        if ( ! $state ){
            $state = $autouse{ $module } = {};
            push @autouse, $module;
            set_autoload( $module );
        }
        if ($param) {
            my @all_import = split ",",        $param || '';
            my @var_import = grep m/^[%\@\$]/, @all_import;
            my @sub_import = grep m/^\w/,      @all_import;
	    if ( @var_import ){
		    $state->{var} = \@var_import;
	    }
	    if (@sub_import){
		    $state->{sub} = \@sub_import;
	    }
        }
    }
    continue {
	    shift @_;
    }
}
sub clean_namespace {
    my $caller = caller;
    if (ref $_[0]){
        $caller = ${ shift() }[0];
    }
    return 1 if caller eq __PACKAGE__;
    my $x = delete $clean_namespace{ $caller };
    my @x;
    @x = keys %$x if $x;
    push @x, 'clean_namespace';
    push @x, @_;

    for (@x) {
        next unless m/^\w+\z/;
        delete ${ $caller . '::' }{$_};
    }
    'yes!';
}
sub unimport{
    $^H ^= $^H & 0x00000002;
}
# load site define options
# Prevent Real::Handy loading twice
$INC{'Real/Handy.pm'} ||= 'S';
1;

# Preloaded methods go here.
__END__
=head1 NAME

Real::Handy - Perl extension for fast developing 

=head1 SYNOPSIS

	use Real::Handy;
#   instead of:
#   use strict;
#   use warnings; no warnings 'uninitialized';
#   use Data::Dumper;
#   use autouse;
#   use Carp;
#   use FCGI;
#   use ... Some other usefull module
#   use 5.010; for given, state, say
#   use Scalar::Util
#   use utf8;


=head1 DESCRIPTION

	See explanation of Toolkit.

=head1 SEE ALSO


=head1 AUTHOR

GTOLY, E<lt>grian@cpanE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by grian

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
