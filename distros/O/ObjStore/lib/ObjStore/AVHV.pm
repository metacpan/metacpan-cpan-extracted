use strict;
package ObjStore::AVHV::Fields;
use Carp;
use ObjStore;
use base 'ObjStore::HV';
use vars qw($VERSION %LAYOUT_VERSION);
$VERSION = '0.02';

'ObjStore::Database'->
    _register_private_root_key('layouts', sub { 'ObjStore::HV'->new(shift, 30) });

#push(@ObjStore::Database::OPEN1, \&verify_class_fields); #dubious

sub nuke_class_fields {
    return if $] < 5.00450;
    warn "nuke_class_fields: this is for debugging only...";
    my ($db) = @_;
    my $layouts = $db->_private_root_data('layouts');
    return if !$layouts;
    %$layouts = ();
}

sub is_compat {
    my ($l, $tlay) = @_;
    for my $k (keys %$tlay) {
	next if $k =~ m'^_';
	return if ($l->{$k} || -1) != $tlay->{$k};
    }
    1;
}

sub get_transient_layout {
    my ($class) = @_;
    no strict 'refs';
    croak '\%{'.$class.'\::FIELDS} not found'
	if !defined %{"$class\::FIELDS"};
    \%{"$class\::FIELDS"};
}

sub get_certified_layout {
    my ($layouts, $of) = @_;
    my $l = $layouts->{$of};
    return if !$l || !$l->{__VERSION__};

    return $l if $ObjStore::RUN_TIME == ($LAYOUT_VERSION{$of} or 0);

    my $tlay = get_transient_layout($of);
    return if !is_compat($l, $tlay);

    $LAYOUT_VERSION{$of} = $ObjStore::RUN_TIME;
    $l;
}

sub is_newest_layout {
    my ($o) = @_;

    my $class = ref $o;
    return 1 if $ObjStore::RUN_TIME == ($LAYOUT_VERSION{ $class } or 0);

    my $layouts = $o->database_of->_private_root_data('layouts');
    return 0 if !$layouts;
    my $l = get_certified_layout($layouts, $class);
    return 0 if !$l;
    $l == $o->[0];
}

# should create a transient ref to the layout and cache that! XXX
sub new { #XS? XXX
    my ($class, $db, $of) = @_;
    my $layouts = $db->_private_root_data('layouts');

    my $l = get_certified_layout($layouts, $of);
    return $l if $l;

    my $old = $layouts->{$of};
    if ($old and $ObjStore::RUN_TIME == ($old->{__VERSION__} or 0)) {
	confess "ObjStore::AVHV must be notified of run-time manipulation of field layouts by changing \$ObjStore::RUN_TIME to be != \$layout->{__VERSION__}";

	# We only check the previous layout.  Potentially, an older layout
	# could have the same version.  This will be caught by the
	# UNIVERSAL is_evolved check (given a version mismatch!).
    }

    $l = $layouts->{$of} = get_transient_layout($of);
    my $width = 1;
    for (keys %$l) { ++$width if $_ !~ /^_/; }
    $l->{__MAX__} = $width;
    $l->{__VERSION__} = $ObjStore::RUN_TIME;
    $l->{__CLASS__} = $of;
    bless $l, $class;
    $l->const;
    $LAYOUT_VERSION{$of} = $ObjStore::RUN_TIME;
    $l;
}

sub is_evolved {1} #const anyway

package ObjStore::AVHV;
use Carp;
use base 'ObjStore::AV';
use ObjStore;
use vars qw($VERSION);
$VERSION = '0.04';

sub new {
    require 5.00450;
    my ($class, $near, $init) = @_;
    croak "$class->new(near, init)" if @_ < 2;
    my $fmap = 'ObjStore::AVHV::Fields'->new($near->database_of, $class);
    my $o = $class->SUPER::new($near, $fmap->{__MAX__}+1);
    $o->[0] = $fmap;
    if ($init) {
	confess "$o initializer is not a ref ($init)" if !ref $init;
	while (my ($k,$v) = each %$init) {
	    croak "Bad key '$k' for $fmap" if !exists $fmap->{$k};
	    $o->{$k} = $v;
	}
    }
    $o;
}

sub is_evolved {
    local $Carp::CarpLevel = $Carp::CarpLevel+1;
    my ($o) = @_;
    return 0 if !$o->SUPER::is_evolved();
    ObjStore::AVHV::Fields::is_newest_layout($o);
}

sub _avhv_relayout {
    require 5.00450;
    my ($o, $to) = @_;
    my $new = 'ObjStore::AVHV::Fields'->new($o->database_of, $to);
    return if $$o[0] && $new == $o->[0];
    
    my $old = $o->[0];
    ObjStore::peek($old), croak "Found $old where ObjStore::AVHV::Fields expected"
	if ($old && !$old->isa('ObjStore::AVHV::Fields') &&
	    !$old->isa('ObjStore::HV'));

    #copy interesting fields to @tmp
    my @save;
    while (my ($k,$v) = each %$old) {
	next if $k =~ m'^_';
	push(@save, [$k,$o->[$v]]) if exists $new->{$k};
    }
    
    #clear $o & copy @save back using new schema
    for (my $x=0; $x < $o->FETCHSIZE(); $x++) { $o->[$x] = undef }
    for my $z (@save) { $o->[ $new->{$z->[0]} ] = $z->[1]; }
    $o->[0] = $new;
    ();
}

sub BLESS {
    return shift->SUPER::BLESS(@_) if ref $_[0];
    my ($class, $o) = @_;
    _avhv_relayout($o, $class);
    $class->SUPER::BLESS($o);
}

sub evolve { bless $_[0], ref($_[0]); }

#sub readonly {
#    my ($o,$k) = @_;
#    my $x = $o->[0]->{$k};
#    die "Bad index while coercing array into hash ($k)" if $x<1;
#    $o->SUPER::readonly($x);
#}

sub POSH_CD {
    my ($o,$k) = @_;
    return if $k =~ m/^_/;
    my $fm = $o->[0];
    return unless exists $fm->{$k};
    $o->[ $fm->{$k} ];
}

# Hash style, but in square brackets
sub POSH_PEEK {
    require 5.00450;
    my ($val, $o, $name) = @_;
    my $fm = $val->[0];
    my @F = sort grep(!m'^_', keys %$fm);
    $o->{coverage} += scalar @F;
    my $big = @F > $o->{width};
    my $limit = $big ? $o->{summary_width}-1 : $#F;
    
    $o->o($name . " [");
    $o->nl;
    $o->indent(sub {
	for my $x (0..$limit) {
	    my $k = $F[$x];
	    my $v = $val->[$fm->{$k}];
	    
	    $o->o("$k => ");
	    $o->peek_any($v);
	    $o->nl;
	}
	if ($big) { $o->o("..."); $o->nl; }
    });
    $o->o("],");
    $o->nl;
}

1;

=head1 NAME

  ObjStore::AVHV - Hash interface, array performance

=head1 SYNOPSIS

  package MatchMaker::Person;
  use base 'ObjStore::AVHV';
  use fields qw( height hairstyle haircolor shoetype favorites );

=head1 DESCRIPTION

Support for extremely efficient records.

Even without optimization or benchmarks, the memory savings achieved
by factoring the hash keys is quite significant and a large
performance win.  Perl implements a similar strategy by globally
sharing hash keys across all (transient) hashes.

=head1 TODO

=over 4

=item * More documentation

=item *

This could be implemented with zero per-record overhead if we stored
the layout in a per-class global.  This would definitely be slower
though.

=back

=cut
