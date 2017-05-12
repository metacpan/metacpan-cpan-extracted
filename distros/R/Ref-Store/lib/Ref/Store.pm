package Ref::Store;
use strict;
use warnings;

our $VERSION = '0.20';

use Scalar::Util qw(weaken);
use Carp::Heavy;
use Ref::Store::Common;
use Ref::Store::Attribute;
use Ref::Store::Dumper;
use Scalar::Util qw(weaken isweak);
use Devel::GlobalDestruction;
use Data::Dumper;
use Log::Fu { level => "debug" };
use Carp qw(confess cluck);
use Devel::FindRef qw(ptr2ref);

use base qw(Ref::Store::Feature::KeyTyped Exporter);
our (@EXPORT,@EXPORT_OK,%EXPORT_TAGS);

use Constant::Generate [qw(
	REF_STORE_FALSE
	REF_STORE_TRUE
	
	REF_STORE_KEY
	REF_STORE_ATTRIBUTE
	
)], -tag => 'ref_store_constants',
	-export => 1,
	-export_tags => 1;

use Class::XSAccessor::Array
	accessors	=> { 
        %Ref::Store::Common::LookupNames 
    };

my %Tables; #Global hash of tables

################################################################################
################################################################################
################################################################################
### GENERIC FUNCTIONS                                                        ###
################################################################################
################################################################################
################################################################################
sub _keyfunc_defl {
	my $k = shift;
	if(ref $k) {
		return $k + 0;
	}
	return $k;
}

our $SelectedImpl;

sub new {
	my ($cls,%options) = @_;
	
	if($cls eq __PACKAGE__) {
		if(!defined $SelectedImpl) {
			log_debug("Will try to select best implementation");
			foreach (qw(XS PP Sweeping)) {
				my $impl = $cls . "::$_";
				eval "require $impl";
				if(!$@) {
					$SelectedImpl = $impl;
					last;
				}
			}
		}
		die "Can't load any implmented" unless $SelectedImpl;
		$cls = $SelectedImpl;
		log_debug("Using $SelectedImpl");
	}
	
	$options{keyfunc} ||= \&_keyfunc_defl;
	$options{unkeyfunc} ||= sub { $_[0] };
	
	my $self = [];
	bless $self, $cls;
	
	$self->[$_] = {} for
		(HR_TIDX_FLOOKUP,
		HR_TIDX_RLOOKUP,
		HR_TIDX_SLOOKUP,
		HR_TIDX_ALOOKUP,
		HR_TIDX_KEYTYPES);
	
	$self->[HR_TIDX_KEYFUNC] = $options{keyfunc};
	$self->[HR_TIDX_UNKEYFUNC] = $options{unkeyfunc};
	
	if($self->can('table_init')) {
		$self->table_init();
	}
	
	weaken($Tables{$self+0} = $self);
	return $self;
}

sub purge {
	my ($self,$value) = @_;
	return unless defined $value;
	my $vstring = $value + 0;
		
	foreach my $ko (values %{ $self->reverse->{$vstring} }) {
		if(!defined $ko) {
			die "Found stale key object!";
		}
		$ko->unlink_value($value);
	}
	
	$self->dref_del_ptr($value, $self->reverse, $value + 0);
	delete $self->reverse->{$vstring};
	return $value;
}

#Not fully implemented
sub exchange_value {
	my ($self,$old,$new) = @_;
	my $olds = $old+0;
	my $news = $new + 0;
	die "Can't switch to existing value!" if exists $self->reverse->{$news};
	
	return unless exists $self->reverse->{$olds};
	
	my $newh = {};
	my $oldh = $self->reverse->{$olds};
	$self->reverse->{$news} = $newh;
	
	while (my ($kaddr,$kobj) = each %$oldh) {
		$newh->{$kaddr} = $kobj;
		$kobj->exchange_value($old,$new);
		delete $oldh->{$kaddr};
	}
}

sub register_kt {
	my ($self,$kt,$id_prefix) = @_;
	if(!$self->keytypes) {
		$self->keytypes({});
	}
	$id_prefix ||= $kt;
	if(!exists $self->keytypes->{$kt}) {
		#log_info("Registering CONST=$kt PREFIX=$id_prefix");
		$self->keytypes->{$kt} = $id_prefix;
	}
}

sub maybe_cleanup_value {
	my ($self,$value) = @_;
	my $v_rhash = $self->reverse->{$value+0};
	if(!scalar %$v_rhash) {
		delete $self->reverse->{$value+0};
		$self->dref_del_ptr($value, $self->reverse, $value + 0);
	} else {
		#log_warn(scalar %$v_rhash);
	}
}

################################################################################
################################################################################
################################################################################
### INFORMATIONAL FUNCTIONS                                                  ###
################################################################################
################################################################################
################################################################################
sub has_key {
	my ($self,$key) = @_;
	$key = ref $key ? $key + 0 : $key;
	return (exists $self->forward->{$key} || exists $self->scalar_lookup->{$key});
}

*lexists = \&has_key;

sub has_value {
	my ($self,$value) = @_;
	return 0 if !defined $value;
	$value = $value + 0;
	return exists $self->reverse->{$value};
}

sub vlookups {
	my ($self,$value) = @_;
	my @ret;
	$value = $value + 0;
	my $vhash = $self->reverse->{$value};
	$vhash ||= {};
	foreach my $ko (values %$vhash) {
		push @ret, $ko->kstring;
	}
	return @ret;
}

*vexists = \&has_value;

sub has_attr {
	my ($self,$attr,$t) = @_;
	$self->attr_get($attr, $t);
}

sub is_empty {
	my $self = shift;
	%{$self->scalar_lookup} == 0
		&& %{$self->reverse} == 0
		&& %{$self->forward} == 0
		&& %{$self->attr_lookup} == 0;
}

sub vlist {
	my $self = shift;
	return map { Devel::FindRef::ptr2ref $_+0 } keys %{ $self->reverse };
}

sub _mk_keyspec {
	my $lookup = shift;
	my $prefix;
	my $kstring = $lookup->kstring;
	my $ukey = $lookup->ukey;
	$ukey = $kstring unless defined $ukey;
	if($lookup->prefix_len) {
		$prefix = substr($kstring, 0, $lookup->prefix_len);
		if(!ref $ukey) {
			$ukey = substr($kstring, $lookup->prefix_len+1);
		}
	} else {
		$prefix = "";
	}
	return ($prefix, $ukey);
}

sub klist {
	my ($self,%options) = @_;
	my @ret;
	foreach my $kobj (values %{$self->forward}) {
		push @ret, [REF_STORE_KEY, _mk_keyspec($kobj)];
	}
	foreach my $aobj (values %{$self->attr_lookup}) {
		push @ret, [REF_STORE_ATTRIBUTE, _mk_keyspec($aobj)];
	}
	return @ret;
}


#This is the iteration mechanism. An 'iterator' is an internal structure
#which keeps track of the items we wish to iterate over. the CUR field
#is a simple integer. the HASH field is an array of hashrefs, with the
#current active hash specified with the CUR field; thus the currently
#iterated-over hash is $iter->[ITER_FLD_HASH]->[ $iter->[ITER_FLD_CUR] ];
# When the CUR field reaches ITER_CUR_END, it means there are no more
#hashes to iterate over.
use constant {
	ITER_FLD_HASH 	=> 0,
	ITER_FLD_CUR	=> 1,
	
	ITER_CUR_KEYS	=> 0,
	ITER_CUR_ATTR	=> 1,
	ITER_CUR_END	=> 2
};
sub iterinit {
	my ($self,%options) = @_;
	
	warn("Resetting existing non-null iterator") if defined $self->_iter;
	
	keys %{$self->scalar_lookup};
	keys %{$self->attr_lookup};
	my $iter = [];
	$iter->[ITER_FLD_CUR] = 0;
	
	$iter->[ITER_FLD_HASH]->[ITER_CUR_KEYS] = $self->scalar_lookup;
	$iter->[ITER_FLD_HASH]->[ITER_CUR_ATTR] = $self->attr_lookup;
	
	if($options{OnlyKeys}) {
		delete $iter->[ITER_FLD_HASH]->[ITER_CUR_ATTR];
	} elsif ($options{OnlyAttrs}) {
		delete $iter->[ITER_FLD_HASH]->[ITER_CUR_KEYS];
		$iter->[ITER_FLD_CUR]++;
	}
	$self->_iter($iter);
	return;
}

sub iterdone {
	my $self = shift;
	$self->_iter(undef);
}

sub iter {
	my $self = $_[0];
	my $iter = $self->_iter;
	return unless $iter;
	my @ret;
	#print Dumper($iter);
	my $nextk = each %{$iter->[ITER_FLD_HASH]->[ $iter->[ITER_FLD_CUR] ] };
	goto GT_EMPTY unless defined $nextk;
	
	my $lookup = $iter->[ITER_FLD_HASH]->[ $iter->[ITER_FLD_CUR] ]->{$nextk};
	
	goto GT_EMPTY unless defined $lookup;
	
	
	
	if($iter->[ITER_FLD_CUR] == ITER_CUR_KEYS) {
		@ret = (REF_STORE_KEY,
				_mk_keyspec($lookup),
				$self->forward->{$lookup->kstring});
	} else {
		#Attribute		
		@ret = (REF_STORE_ATTRIBUTE,
				_mk_keyspec($lookup),
				[values %{$lookup->get_hash}]);
	}
	return @ret;
	
	GT_EMPTY:
	while($iter->[ITER_FLD_CUR]++ < ITER_CUR_END) {
		if($iter->[ITER_FLD_HASH]->[ $iter->[ITER_FLD_CUR ] ]) {
			goto &iter;
		}
	}
	#End!
	$self->_iter(undef);
	return ();
}

sub dump {
	my $self = shift;
	my $dcls = "Ref::Store::Dumper";
	my $hrd = $dcls->new();
	#my $hrd = Ref::Store::Dumper->new();
	#log_err($hrd);
	$hrd->dump($self);
	$hrd->flush();
	#print Dumper($self);
}
################################################################################
################################################################################
################################################################################
### KEY FUNCTIONS                                                            ###
################################################################################
################################################################################
################################################################################
sub new_key {
	die "new_key not implemented!";
}

sub ukey2ikey {
	my ($self, $ukey, %options) = @_;
	
	my $ustr = $self->keyfunc->($ukey);
	my $expected = delete $options{O_EXCL};
	my $create_if_needed = delete $options{Create};
	
	#log_info($ustr);
	my $o = $self->scalar_lookup->{$ustr};
	if($expected && $o) {
		my $existing = $self->forward->{$o->kstring};
		if($existing && $expected != $existing) {
			die "Request O_EXCL for new key ${\$o->kstring} => $expected but key ".
			"is already tied to $existing";
		}
	}
	
	if(!$o && $create_if_needed) {
		$o = $self->new_key($ukey);
		if(!$options{StrongKey}) {
			$o->weaken_encapsulated();
		}
	}
	
	return $o;
}

sub store_sk {
	my ($self,$ukey,$value,%options) = @_;
	my $o = $self->ukey2ikey($ukey,
		Create => 1,
		O_EXCL => $value,
		%options
	);
	my $vstring = $value+0;
	my $kstring = $o->kstring;
	$self->reverse->{$vstring}->{$kstring} = $o;
	$self->forward->{$kstring} = $value;
	
	#Add a back-delete to the reverse entry. The forward
	#entry for keys are handled by the keys themselves.
	$self->dref_add_ptr($value, $self->reverse);
	$o->link_value($value);
	
	if(!$options{StrongValue}) {
		weaken($self->forward->{$kstring});
	}
	return $value;
}
*store = \&store_sk;


#sub store_kt {
#	my ($self,$ukey,$prefix,$value,%options) = @_;
#	
#}

sub fetch_sk {
	my ($self,$ukey) = @_;
	#log_info("called..");
	my $o = $self->ukey2ikey($ukey);
	return unless $o;
	return $self->forward->{$o->kstring};
}
*fetch = \&fetch_sk;

#This dissociates a value from a single key
sub unlink_sk {
	my ($self,$ukey) = @_;
	
	my $ko = $self->ukey2ikey($ukey);
	return unless $ko;
	my $value = $self->forward->{$ko->kstring};
	die "Found orphaned key $ko" unless defined $value;
	
	my $vstr = $value + 0;
	my $kstr = $ko->kstring;
	
	my $vhash = $self->reverse->{$vstr};
	
	die "Can't locate vhash" unless defined $vhash;
	delete $vhash->{$kstr};
	
	$ko->unlink_value($value);
	
	if(!%{$self->reverse->{$vstr}}) {
		delete $self->reverse->{$vstr};
		$self->dref_del_ptr($value, $self->reverse, $vstr);
		
	}
	
	return $value;
}
*unlink = \&unlink_sk;

sub purgeby_sk {
	my ($self,$kspec) = @_;
	my $value = $self->fetch($kspec);
	return unless $value;
	$self->purge($value);
	return $value;
}

*purgeby = \&purgeby_sk;

*lexists_sk = \&lexists;

################################################################################
################################################################################
################################################################################
### ATTRIBUTE FUNCTIONS                                                      ###
################################################################################
################################################################################
################################################################################
sub new_attr {
	my ($self,$astr,$attr) = @_;
	my $cls = ref $attr ? 'Ref::Store::Attribute::Encapsulating' :
		'Ref::Store::Attribute';
	$cls->new($astr,$attr,$self);
}

sub attr_get {
    my ($self,$attr,$t,%options) = @_;
	
    my $ustr = $self->keytypes->{$t} or die "Couldn't find attribtue type!";
    $ustr .= "#";
    if(ref $attr) {
        $ustr .= $attr+0;
    } else {
        die unless $attr;
        $ustr .= $attr;
    }
    my $aobj = $self->attr_lookup->{$ustr};
    return $aobj if $aobj;
    
    if(!$options{Create}) {
        return;
    }
    
    $aobj = $self->new_attr($ustr, $attr, $self);
	weaken($self->attr_lookup->{$ustr} = $aobj);
	
    if(!$options{StrongAttr}) {
		$aobj->weaken_encapsulated();
    }
    return $aobj;
}

sub store_a {
    my ($self,$attr,$t,$value,%options) = @_;
	
    my $aobj = $self->attr_get($attr, $t, Create => 1, %options);
	if(!$value) {
		log_err(@_);
		die "NULL Value!";
	}

    my $vaddr = $value + 0;

	$self->reverse->{$vaddr}->{$aobj+0} = $aobj;
    
    if(!$options{StrongValue}) {
        $aobj->store_weak($vaddr, $value);
    } else {
        $aobj->store_strong($vaddr, $value);
    }

    #add back-delete references to both the private
    #attribute hash as well as the reverse entry.
	
    $self->dref_add_ptr($value, $aobj->get_hash);
    $self->dref_add_ptr($value, $self->reverse);
    $aobj->link_value($value);
	
    return $value;
}


sub fetch_a {
    my ($self,$attr,$t) = @_;
    my $aobj = $self->attr_get($attr, $t);
	if(!$aobj) {
		#log_err("Can't find attribute object! ($attr:$t)");
		#print Dumper($self->attr_lookup);
		return;
	}
	my @ret;
	return @ret unless $aobj;
	@ret = values %{$aobj->get_hash};
	return @ret;
}

sub purgeby_a {
    my ($self,$attr,$t) = @_;
    my @values = $self->fetch_a($attr, $t);
    $self->purge($_) foreach @values;
	return @values;
}

sub dissoc_a {
    my ($self,$attr,$t,$value) = @_;
    my $aobj = $self->attr_get($attr, $t);
	if(!$aobj) {
		log_err("Can't find attribute for $t$attr");
		return;
	}
	my $attrhash = $aobj->get_hash;
	delete $attrhash->{$value+0};
	delete $self->reverse->{$value+0}->{$aobj+0};
	$self->dref_del_ptr($value, $attrhash, $value+0);

	$aobj->unlink_value($value);
	$self->maybe_cleanup_value($value);
}

sub unlink_a {
    my ($self,$attr,$t) = @_;
    my $aobj = $self->attr_get($attr, $t);
	my $attrhash = $aobj->get_hash;
    return unless $attrhash;
	
	
	while (my ($k,$v) = each %$attrhash) {
		$self->dref_del_ptr($v, $attrhash, $v+0);
		delete $attrhash->{$k};
		delete $self->reverse->{$v+0}->{$aobj+0};
		$aobj->unlink_value($v);
		$self->maybe_cleanup_value($v);
	}
}


*lexists_a = \&has_attr;

sub Dumperized {
	my $self = shift;
	return {
		'Reverse Lookups' => $self->reverse,
		'Forward Lookups' => $self->forward,
		'Scalar Lookups' => $self->scalar_lookup,
		'Attribute Lookups' => $self->attr_lookup
	};
}

sub DESTROY {
	return if in_global_destruction;
	my $self = shift;
	#log_err("Destroying $self...");
	my @values;
	foreach my $attr (values %{$self->attr_lookup}) {
		#log_warn("Attr: $attr");
		my $attrhash = $attr->get_hash();
		next unless ref $attrhash;
		if(ref $attrhash ne 'HASH') {
			use Devel::Peek;
			Devel::Peek::Dump($attrhash);
		}
		foreach my $v (values %$attrhash) {
			next unless defined $v;
			if($attr->can('unlink_value')) {
				$attr->unlink_value($v);
			}
			push @values, $v;
		}
	}
	#log_warn("Attribute deletion done");
	
	foreach my $kobj (values %{$self->scalar_lookup}) {
		my $v = $self->forward->{$kobj->kstring};
		push @values, $v;
		if($kobj->can("unlink_value")) {
			$kobj->unlink_value($v);
		}
		delete $self->scalar_lookup->{$kobj->kstring};
		delete $self->forward->{$kobj->kstring};
	}
	
	#log_warn("Key deletion done");
	
	foreach my $value (@values) {
		my $vaddr = $value + 0 ;
		my $vhash = delete $self->reverse->{$vaddr};
		#log_warn($vhash);
		$self->dref_del_ptr($value, $self->reverse, $vaddr);
	}
	#log_warn("Will clear temporary value list");
	undef @values;
	
	delete $Tables{$self+0};
	#log_err("Destroy $self done");
}

################################################################################
################################################################################
### Thread Cloning                                                           ###
################################################################################
################################################################################

#This maps addresses to (weak) object references
our %CloneAddrs;

sub ithread_predup {
	my $self = shift;
	
	$self->ithread_store_lookup_info(\%CloneAddrs);
	
	#Key lookups
	foreach my $val (values %{$self->forward}) {
		weaken($CloneAddrs{$val+0} = $val);
	}
	
	foreach my $kobj (values %{$self->scalar_lookup}) {
		weaken($CloneAddrs{$kobj+0} = $kobj);
		
		my $v = $self->forward->{$kobj->kstring};
		$kobj->ithread_predup($self, \%CloneAddrs, $v);
	}
	
	foreach my $attr (values %{$self->attr_lookup}) {
		weaken($CloneAddrs{$attr+0} = $attr);
		$attr->ithread_predup($self, \%CloneAddrs);
		my $attrhash = $attr->get_hash;
		#log_warn("ATTRHASH", $attrhash);
		foreach my $v (values %$attrhash) {
			weaken($CloneAddrs{$v+0} = $v);
		}
	}
	
	foreach my $vhash (values %{$self->reverse}) {
		#log_warn($vhash);
		weaken($CloneAddrs{$vhash+0} = $vhash);
	}
	#foreach (qw(attr_lookup scalar_lookup forward reverse)) {
	#	log_warn($_, $self->can($_)->($self));
	#}
}

sub ithread_postdup {
	my ($self,$old_table) = @_;
	
	my @oldkeys = keys %{$self->reverse};
	foreach my $oldaddr (@oldkeys) {
		my $vhash = $self->reverse->{$oldaddr};
		my $vobj = $CloneAddrs{$oldaddr};
		if(!defined $vobj) {
			print Dumper(\%CloneAddrs);
			die("KEY=$oldaddr");
		}
		my $newaddr = $vobj + 0;
		$self->reverse->{$newaddr} = $vhash;
		delete $self->reverse->{$oldaddr};
		$self->dref_add_ptr($vobj, $self->reverse, $newaddr);
	}
	
	@oldkeys = keys %{$self->scalar_lookup};
	foreach my $kstring (@oldkeys) {
		my $kobj = $self->scalar_lookup->{$kstring};
		$kobj->ithread_postdup($self, \%CloneAddrs, $old_table);
		my $new_kstring = $kobj->kstring;
		
		next unless $new_kstring ne $kstring;
		my $weak_key = isweak($self->scalar_lookup->{$kstring});
		my $weak_val = isweak($self->forward->{$kstring});
		
		delete $self->scalar_lookup->{$kstring};
		my $v = delete $self->forward->{$kstring};
		
		$self->scalar_lookup->{$new_kstring} = $kobj;
		$self->forward->{$new_kstring} = $v;
		
		if($weak_key) {
			weaken($self->scalar_lookup->{$new_kstring});
		}
		if($weak_val) {
			weaken($self->forward->{$new_kstring});
		}
	}
		
	@oldkeys = keys %{$self->attr_lookup};
	foreach my $astring (@oldkeys) {
		my $aobj = $self->attr_lookup->{$astring};
		$aobj->ithread_postdup($self, \%CloneAddrs);
		my $new_astring = $aobj->kstring;
		
		next unless $new_astring ne $astring;
		
		delete $self->attr_lookup->{$astring};
		weaken($self->attr_lookup->{$new_astring} = $aobj);
	}
	
	#foreach (qw(attr_lookup scalar_lookup forward reverse)) {
	#	log_warn($_, $self->can($_)->($self));
	#}
	
	foreach my $vhash (values %{$self->reverse}) {
		my @vhkeys = keys %$vhash;
		foreach my $lkey (@vhkeys) {
			my $lobj = delete $vhash->{$lkey};
			$vhash->{$lobj->kstring} = $lobj;
		}
	}
}

$SIG{__DIE__}=\&confess;
sub CLONE_SKIP {
	my $pkg = shift;
	return 0 if $pkg ne __PACKAGE__;
	$Log::Fu::LINE_PREFIX = 'PARENT: ';
	%CloneAddrs = ();
	
	while ( my ($addr,$obj) = each %Tables ) {
		if(!defined $obj) {
			log_err("Found undefined reference T=$addr");
			#die("Found undef table in hash");
			delete $Tables{$addr};
			next;
		}
		$obj->ithread_predup();
	}
	
	return 0;
}

sub CLONE {
	my $pkg = shift;
	return if $pkg ne __PACKAGE__;
	$Log::Fu::LINE_PREFIX = 'CHILD: ';
	my @tkeys = keys %Tables;
	my @new_tables;
	foreach my $old_taddr (@tkeys) {
		my $table = delete $Tables{$old_taddr};
		#log_info("Calling ithread_postdup on table");
		$table->ithread_postdup($old_taddr);
		#log_info("Done");
		weaken($Tables{$table+0} = $table);
	}
	
	%CloneAddrs = ();
}
1;

__END__

=head1 NAME

Ref::Store - Store objects, index by object, tag by objects - all without
leaking.


=head1 SYNOPSIS

	my $table = Ref::Store->new();
	
Store a value under a simple string key, maintain the value as a weak reference.
The string key will be deleted when the value is destroyed:

	$table->store("key", $object);

Store C<$object> under a second index (C<$fh>), which is a globref;
C<$fh> will automatically be garbage collected when C<$object> is destroyed.

	{
		open my $fh, ">", "/foo/bar";
		$table->store($fh, $object, StrongKey => 1);
	}
	# $fh still exists with a sole reference remaining in the table
	
Register an attribute type (C<foo_files>), and tag C<$fh> as being one of C<$foo_files>,
C<$fh> is still dependent on C<$object>

	# assume $fh is still in scope
	
	$table->register_kt("foo_files");
	$table->store_a(1, "foo_files", $fh);

Store another C<foo_file>
	
	open my $fh2, ">", "/foo/baz"
	$table->store_a(1, "foo_files", $fh);
	# $fh2 will automatically be deleted from the table when it goes out of scope
	# because we did not specify StrongKey
	
Get all C<foo_file>s

	my @foo_files = $table->fetch_a(1, "foo_files");
	
	# @foo_files contains ($fh, $fh2);
	
Get rid of C<$object>. This can be done in one of the following ways:
	
	# Implicit garbage collection
	undef $object;
	
	# Delete by value
	$table->purge($object);
	
	# Delete by key ($fh is still stored under the foo_keys attribute)
	$table->purgeby($fh);

	# remove each key for the $object value
	$table->unlink("key");
	$table->unlink($fh); #fh still exists under "foo" files
	
Get rid of C<foo_file> entries
	
	# delete, by attribute
	$table->purgeby_a(1, "foo_files");
	
	# delete a single attribute from all entries
	$table->unlink_a(1, "foo_files");
	
	# dissociate the 'foo_files' attribtue from each entry
	$table->dissoc_a(1, "foo_files", $fh);
	$table->dissoc_a(1, "foo_files", $fh2);
	
	# implicit garbage collection:
	undef $fh;
	undef $fh2;

For a more detailed walkthrough, see L<Ref::Store::Walkthrough>
	
=head1 DESCRIPTION

Ref::Store provides an efficient and worry-free way to index objects by
arbitrary data - possibly other objects, simple scalars, or whatever.

It relies on magic and such to ensure that objects you put in the lookup table
are not maintained there unless you want them to be. In other words, you can store
objects in the table, and delete them without having to worry about what other
possible indices/references may be holding down the object.

If you are looking for something to store B<Data>, then direct your attention to
L<KiokuDB>, L<Tangram> or L<Pixie> - these modules will store your I<data>.

However, if you are specifically wanting to maintain garbage-collected and reference
counted perl objects, then this module is for you. continue reading.


=head2 FEATURES

=head3 The problem

I've had quite the difficult task of explaining what this module actually does.

Specifically, C<Ref::Store> is intended for managing and establishing dependencies
and lookups between perl objects, which at their most basic levels are opaque
entities in memory that are reference counted.

The lifetime of an object ends when its reference count hits zero, meaning that
no data structure or code is referring to it.

When a new object is created (normally done through C<bless>), it has a reference
count of 1. As more copies of the object reference are made, the reference count
of the object increases.

What this also means is that each time an object is inserted into a hash as a
value, its reference count increases - and as a result, the object (and all
other objects which it contains) will not be destroyed until it is removed
from all those hashes.

Perl core offers the concept of a I<weak> reference, and is exposed to perl code
via L<Scalar::Util>'s weaken. Weak references allow the maintaining of an object
reference without actually increasing the object's reference count.

Internally (in the Perl core), the object maintains a list of all weak references
referring to it, an when the object's own reference count hits zero, those
weak references are changed to C<undef>.

As this relates to hash entries, the value of the entry becomes C<undef>, but
the entry itself is not deleted.

	use Scalar::Util qw(weaken);
	my %hash;
	my $object = \do { my $o };
	weaken($hash{some_key} = $object);
	undef $object;
	
	#The following will be true:
	exists$hash{some_key} && $hash{some_key} == undef;
	
When iterating over the hash keys, one must then check to see if the value is
undefined - which is often a messy solution.

If the hash's values are constantly being changed and updated, but not frequently
iterated through, this can cause a significant memory leak.

Additionally, weakref semantics are cumbersome to deal with in pure perl. The
weakness of a reference only applies to that specific variable; therefore, the
general semantics of C<my $foo = $bar>, where $foo is understood to be an exact
replica of C<$bar> are broken. If C<$bar> is a weak reference, C<$foo> does not
retain such a property, and will increase the reference count of whatever foo and
bar refer to.

Dealing with collection items, especially tied hashes and arrays becomes even
more cumbersome. In some perls, doing the following with
a tied hash will not work:

	weaken($foo);
	$tied_hash{some_key} = $foo;
	
	# $foo is copied to the tied hash's STORE method.
	
This bug has since been fixed, but not everyone has the luxury of using the newest
and shiniest Perl.

=head3 Other modules and their featuresets

In the event that weak reference keys are needed, there are several modules
that implement solutions:

L<Tie::RefHash::Weak> is a pure-perl tied hash
which maintains weak keys. However it will not necessarily do the same for values,
even when C<weaken> is used explicitly, because of aforementioned bugs. It is also
significantly slow due to its C<TIE> interface.


L<Hash::Util::FieldHash> is part of core since perl 5.10, and depends on something
known as Hash C<uvar> magic, a new feature introduced in 5.10. It does not suffer
from the slowness of L<Tie::RefHash::Weak>, and allows you to (manually) create
weak values. However, keys used for C<FieldHash> are permanently associated with
the hash they have been keyed to, even if the entry or hash have been deleted.


L<Hash::FieldHash> attempts to eliminate the version dependencies and caveats
of C<Hash::Util::FieldHash>, but restricts the keys to only being references.


=head3 Ref::Store's featureset

C<Ref::Store> supports all features in the above mentioned modules, and the following

=over

=item By-Value garbage collection

When a value is stored as a weak reference (see the next section)
and itsreference count hits
zero, then the entire hash entry is deleted; the table does not collect stale entries

=item By-Value deletion

Unlike normal hashes, C<Ref::Store> can quickly and efficiently delete a value
and all its dependent keys given just the value. No need to remember any lookup
key under which the value has been stored

=item Multi-Value keys (Attributes)

Traditional hashes only allow storing of a single value under a single key. For
multi-value storage under a single key, one must fiddle with nested data structures.

Like single-value keys, attributes may be reference objects, and will be discarded
from the hash when the last remaining value's reference count hits zero.

Additionally, the same reference attribute object can serve as a key for multiple
independent value sets, allowing to logically decouple collections which are
dependent on a single object.

=item User defined retention policy

For each key and value, it is possible to define whether either the key, the value,
or both should be strong or weak references. C<Ref::Store> by default stores
keys and values as weak references, but can be modified on a per-operation basis.

Values can also be stored multiple times under multiple keys with different
retention policies: maintain a single 'primary' index, and multiple 'secondary'
indices.

=item Speed

Most of the features are implemented in C, some because of speed, and others
because there was no pure-perl way to do it (See the C<PP> backend, which is
fairly buggy)

=item Works on perl 5.8

This has been tested and developed for perl 5.8.8 (which is the perl provided in
el5).

=back

Here are some caveats

=over

=item No Hash Syntax

C<Ref::Store> is a proper object. You cannot use the table as an actual hash
(though it would be easy enough to wrap it in the C<tie> interface, it would
be signficantly slower, and suffer from other problems related to C<tie>)

=item Slow/Untested thread cloning

While attempts have been made to make this module thread-safe, there are strange
messages about leaked scalars and unbalanced string tables when dealing with threads.

=item Values Restricted to References

Values themselves must be reference objects. It's easy enough, however, to do

	$table->store("foo", \"foo");
	${$table->fetch("foo")} eq "foo";
	
=item Slower than C<Hash::Util::FieldHash>

This module is about 40% slower than C<Hash::Util::FieldHash>

=item Must use Attribute API for multi-entry lookup objects

If you wish to use the same key twice, the key must be used with the Attribute
API, and not the (faster) key API

=back

=head1 API

=head2 LOOKUP TYPES

There are three common lookup types by which values can be indexed and mapped to.

A B<Lookup Type> is just an identifier by which one can fetch and store a value.
The uniqueness of identifiers is dependent on the lookup type. Performance for various
lookup types varies.

Each lookup type has a small tag by which API functions pertaining to it can
be identified

=over

=item Value-specific operations

These functions take a B<value> as their argument, and work regardless of the lookup
type

=over

=item purge($value)

Remove C<$value> from the database. For all lookup types which are linked to C<$value>,
they will be removed from the database as well if they do not link to any other
values

=item vexists($value)

Returns true if C<$value> is stored in the database

=back

=item Simple Key (SK)

This is the quickest and simplest key type. It can use either string or object keys.
It support. The functions it supports are 

=over

=item store($key, $value, %options)

Store C<$value> under lookup <$key>. Key can be an object reference or string.

A single value can be stored under multiple keys, but a single key can only be linked
to a single value.

Options are two possible hash options:

=over

=item StrongKey

If the key is an object reference, by default it will be weakened in the databse,
and when the last reference outside the database is destroyed, an implicit L</unlink>
will be called on it. Setting C<StrongKey> to true will disable this behavior and
not weaken the key object.

A strong key is still deleted if its underlying value gets deleted

=item StrongValue

By default the value is weakened before it is inserted into the database, and when
the last external reference is destroyed, an implicit L</purge> is performed. Setting
this to true will disable this behavior and not weaken the value object.

=back

It is important to note the various rules and behaviors with key and value
storage options.

There are two conditions under which an entry (key and value) may be deleted from
the table. The first condition is when a key or value is a reference type, and
its referrent goes out of scope; the second is when either a key or a value is
explicitly deleted from the table.

It is helpful to think of entries as a miniature version of implicit reference
counting. Each key represents an inherent increment in the value's reference
count, and each key has a reference count of one, represented by the amount of
values it actually stores.

Based on that principle, when either a key or a value is forced to I<leave> the
table (either explicitly, or because its referrant has gone out of scope), its
dependent objects decrease in their table-based implicit references.

Consider the simple case of implicit deletion:

	{
		my $key = "string":
		my $value = \my $foo
		$table->store($key, $foo);
	}
	
In which case, the string C<"string"> is deleted from the table as $foo goes out
of scope.

The following is slightly more complex
	
	my $value = \my $foo;
	{
		my $key = \my $baz;
		$table->store($key, $value, StrongValue => 1);
	}
	
In this case, C<$value> is removed from the table, because its key object's
referrant (C<$baz>) has gone out of scope. Even though C<StrongValue> was specified,
the value is not deleted because its own referrant (C<$foo>) has been destroyed,
but rather because its table-implicit reference count has gone down to 0 with the
destruction of C<$baz>

The following represents an inverse of the previous block

	my $key = \my $baz;
	{
		my $value = \my $foo;
		$table->store($key, $value, StrongKey => 1);
	}
	
Here C<$value> is removed from the table because naturally, its referrant, C<$foo>
has been destroyed. C<StrongKey> only maintains an extra perl reference to C<$baz>.

However, by specifying both C<StrongKey> and C<StrongValue>, we are able to
completely disable garbage collection, and nothing gets deleted

	{
		my $key = \my $baz;
		my $value = \my $foo;
		$table->store($key, $value, StrongKey => 1, StrongValue => 1);
	}

This method is also available as C<store_sk>.

It is an error to call this method twice on the same lookup <-> value specification.

=item fetch($key)

Returns the value object indexed under C<$key>, if any. Also available under C<fetch_sk>

=item lexists($key)

Returns true if C<$key> exists in the database. Also available as C<lexists_sk>

=item unlink($key)

Removes C<$key> from the database. If C<$key> is linked to a value, and that value
has no other keys linked to it, then the value will also be deleted from the databse.
Also available as C<unlink_sk>
	
	$table->store("key1", $foo);
	$table->store("key2", $foo);
	$table->store("key3", $bar);
	
	$table->unlink("key1"); # $foo is not deleted because it exists under "key2"
	$table->unlink("key3"); # $bar is deleted because it has no remaining lookups
	
=item purgeby($key)

If C<$key> is linked to a value, then that value is removed from the database via
L</purge>. Also available as C<purgeby_sk>.

These two blocks are equivalent:
	
	# 1
	my $v = $table->fetch($k);
	$table->purge($v);
	
	# 2
	$table->purgeby($k);

=back

=item Typed Keys

Typed keys are like simple keys, but with more flexibility. Whereas a simple key
can only store associate any string with a specific value, typed keys allow
for associating the same string key with different values, so long as the
type is different. A scenario when this is useful is associating IDs received from
different libraries, which may be identical, to different values.

For instance:

	use Library1;
	use Library1;
	
	my $hash = Ref::Store->new();
	$hash->register_kt('l1_key');
	$hash->register_kt('l2_key');
	
	#later on..
	my $l1_value = Library1->get_handle();
	my $l2_value = Library2->get_handle();
	
	#assume that this is possible:
	
	$l1_value->ID == $l2_value->ID();
	
	$hash->store_kt($l1_value->ID(), 'l1_key', $l1_value);
	$hash->store_kt($l2_value->ID(), 'l2_key', $l2_value);

Note that this will only actually work for B<string> keys. Object keys can still
only be unique to a single value at a time.


All functions described for L</Simple Keys> are identical to those available for
typed keys, except that the C<$key> argument is transformed into two arguments;

thus:
	
	store_kt($key, $type, $value);
	fetch_kt($key, $type);

and so on.

In addition, there is a function which must be used to register key types:

=over

=item register_kt($ktype, $id)

Register a keytype. C<$ktype> is a constant string which is the type, and C<$id>
is a unique identifier-prefix (which defaults to C<$ktype> itself)

=back

=item Attributes

Whereas keys map value objects according to their I<identities>, attributes map
objects according to arbitrary properties or user defined tags. Hence an attribute
allows for a one-to-many relationship between a lookup index and its corresponding
value.

The common lookup API still applies. Attributes must be typed, and therefore
all attribute functions must have a type as their second argument.

A suffix of C<_a> is appended to all API functions.
In addition, the following differences in behavior and options exist

=over

=item store_a($attr, $type, $value, %options)

Like L</store>, but option hash takes a C<StrongAttr> option instead of a C<StrongKey>
option, which is the same. Attributes will be weakened for all associated values
if C<StrongAttr> was not specified during I<any> insertion operation.

=item fetch_a($attr, $type)

Fetch function returns an I<array> of values, and not a single value.

thus:
	
	my $value = $hash->fetch($key);
	#but
	my @values = $hash->fetch_a($attr,$type);
	
However, storing an attribute is done only one value at a time.

=item dissoc_a($attr, $type, $value)

Dissociates an attribute lookup from a single value. This function is special
for attributes, where a single attribute can be tied to more than a single value.

=item unlink_a($attr, $type)

Removes the attribtue from the database. Since multiple values can be tied to the
same attribute, this can potentially remove many values from the DB. Be sure to
use this function with caution

=back

It is possible to use attributes as tags for boolean values or flags, though the
process right now is somewhat tedious (eventually this API will be extended to allow
less boilerplate)

	use constant ATTR_FREE => "attr_free";
	use constant ATTR_BUSY => "attr_busy";
	
	$hash->register_kt(ATTR_FREE);
	$hash->register_kt(ATTR_BUSY);
	
	$hash->store_a(1, ATTR_FREE, $value); #Value is now tagged as 'free';
	
	#to mark the value as busy, be sure to inclusively mark the busy tag first,
	#and then remove the 'free' mark. otherwise the value will be seen as destroyed
	#and associated references removed:
	
	$hash->store_a(1, ATTR_BUSY, $value);
	$hash->dissoc_a(1, ATTR_FREE, $value);
	
	#mark as free again:
	
	$hash->store_a(1, ATTR_FREE, $value);
	$hash->dissoc_a(1, ATTR_BUSY, $value);
	
The complexities come from dealing with a triadic value for a tag. A tag for a value
can either be true, false, or unset. so C<0, ATTR_FREE> is valid as well.

=back

=head2 CONSTRUCTION

=over

=item new(%options)

Creates a new Ref::Store object. It takes a hash of options:

=over

=item keyfunc

I<only in PP backend>

This function is responsible for converting a key to something 'unique'. The
default implementation checks to see whether the key is a reference, and if so
uses its address, otherwise it uses the stringified value. It takes the user key
as its argument

=back

Ref::Store will try and select the best implementation (C<Ref::Store::XS>
and C<Ref::Store::PP>, in that order). You can override this by seting
C<$Ref::Store::SelectedImpl> to a package of your choosing (which must be
loaded).

=back

=head2 ITERATION

While C<Ref::Store> is not a simple collection object, you can still iterate over
values using the following formats

	#Like keys %hash:
	
	my @keyspecs = $refstore->klist();
	my @values	 = $refstore->vlist();
	
	#Like each %hash;
	
	$refstore->iterinit(); #Initialize the iterator
	while ( my ($lookup_type, $lookup_prefix, $my_key, $my_value) = $refstore->iter )
	{
		#do stuff.. but don't modify the list!
	}
	#Cleanup internal iterator state
	$refstore->iterdone();

Because of the various types of keys which can be stored, all iteration functions
return a 'key specification' - a list of three elements:

=over

=item Lookup Type

This is one of C<REF_STORE_KEY> for key lookups, and C<REF_STORE_ATTRIBUTE> for
attribute lookups (depending on whether this was stored with L<store> or L<store_a>).

The type is necessary to determine which lookup function to call in the event
that a more detailed operation is needed.

=item Prefix/Type

For store functions which use a type (L<store_kt> and L<store_a>), this is
the type. Useful to determine the parameter to call for further operations

=item User Key

This is the actual key which was passed in to the store function. This can
be a string or a reference.

=back

A simpler API which copies its return values in lists are provided:

=over

=item vlist()

Returns a list of all value objects. This list is a copy.

=item klist()

Returns a list of arrayrefs containing key specifications

=over

A more complex iterator API is provided. Unlike the simpler API, this does
not copy its return values, thus saving memory

=over

=item iterinit()

Initialize the internal iterator state. This must be called each time before
anything else happens. Like perl hashes, C<Ref::Store> maintains a global
iterator state; calling C<iterinit> resets it.

It is an error to initialize a possibly active iterator without explicitly
destroying the previous one. Also, modifying the table during iteration could
lead to serious problems. Unlike perl hashes, it is not safe to delete the
currently iterated-over element; this is because the iteration is emulated and
gathered from multiple hash states, and deletion of one element can trigger
subsequent deletions.

If you happen to clobber an old iterator, this module will throw a warning. To
avoid accidentally doing so, call L</iterdone> after you have finished iterating.

=item iter()

Compare to L<each>. Returns a 4-element list, the first three of which are the
key specification, and the last is a value specification. For attribute lookups,
this is an arrayref of values indexed under the attribute, and for key lookups
this is the sole value.

Once this function returns the empty list, there are no more pairs left to
traverse.

=item iterdone()

Call this function if you break out of a loop, or to explicitly de-initialize the
iterator state.

=back

=head2 DEBUGGING/INFORMATIONAL

Often it is helpful to know what the table is holding and indexing, possibly because
there is a bug or because you have forgotten to delete something.

The following functions are available for debugging

=over

=item vexists($value)

Returns true if C<$value> exists in the database. The database internally maintains
a hash of values. When functioning properly, a value should never exist without
a key lookup, but this is still alpha software

=item vlookups($value)

I<not yet implemented>

Returns an array of stringified lookups for which this value is registered

=item lexists(K)

Returns true if the lookup C<K> exists. See the L</API> section for lookup-specific
parameters for C<K>

=item is_empty

Returns true if there are no lookups and no values in the database

=item dump

Prints a tree-like representation of the database. This will recurse the entire
database and print information about all values and all lookup types. In addition,
for object references, it will print the reference address in decimal and hexadecimal,
the actual SV address of the reference, and whether the reference is a weak
reference.

=back

=head2 THREAD SAFETY

C<Ref::Store> is tested as being threadsafe the XS backend.

Due to tricky limitations and ninja-style coding necessary to properly
facilitate threads, thread-safety is not supported in the PP backend,
though YMMV (on my machine, PP thread tests segfault).

Thread safety is quite difficult since reference objects are keyed by their
memory addresses, which change as those objects are duplicated.


=head2 USAGE APPLICATIONS

This module caters to the common, but very narrow scope of opaque perl references.
It cares nothing about what kind of objects you are using as keys or values. It
will never dereference your object or call any methods on it, thus the only
requirement for an object is that it be a perl reference.

Using this module, it is possible to create arbitrarily complex, but completely
leak free dependency and relationship graphs between objects.

Sometimes, expressing object lifetime dependencies in terms of encapsulation is
not desirable. Circular references can happen, and the hierarchy can become
increasingly complex and deep - not just logically, but also syntactically.

This becomes even more unwieldy when the same object has various sets of dependants.

A good example would be a socket server proxy, which accepts requests from clients,
opens a second connection to a third-party server to process the client request,
forwards the request to the client's intended origin server, and then finally
relays the response back to the client.

For most simple applications there is no true need to have multiple dynamically
associated and deleted object entries. The benefits of this module become
apparent in design and ease of use when larger and more complex,
event-oriented systems are in use.

In shorter terms, this module allows you to reliably use a I<Single Source Of Truth>
for your object lookups. There is no need to synchronize multiple lookup tables
to ensure that there are no dangling references to an object you should have deleted

=head1 BUGS AND CAVEATS

Probably many.

The XS backend (which is also the default) is the more stable version. The pure-
perl backend is more of a reference implementation which has come to lag behind
its XS brother because of magical voodoo not possible in a higher level language
like Perl.

Your system will need a working C compiler which speaks C99. I have not tested
this on 

=over

=item *

It is not advisable to store one table within another. Doing so may cause strange
things to happen. It would make more sense to have a table being module-global
anyway, though. C<Ref::Store> is really not a lightweight object.

=item *

It is currently not possible to store key objects with prefixes/types. If you need
prefixed object keys, use the attribute API.


=item *

On my system, making a circular link between two objects will not work properly
in terms of garbage collection; this means the following

	$foo = \do bless { my $o };
	$bar = \do bless { my $o };
	#both objects
	$rs->store($foo, $bar);
	$rs->store($bar, $foo);
	
Will not work on the PP backend. It is fully supported in the default XS backend,
however.

=item *

The iteration and C<klist> APIs are not yet implemented in the PP version

=item *

Keyfunc and friends are not fully implemented, either

=over

=head1 AUTHOR

Copyright (C) 2011 by M. Nunberg

You may use and distribute this program under the same terms as perl itself


=head1 SEE ALSO

=over

=item L<Hash::Util::FieldHash>

Ref::Store implements a superset of Hash::Util::FieldHash, but the latter is
most likely quicker. However, it will only work with perls newer than 5.10

=item L<Tie::RefHash::Weak>

=item L<Variable::Magic>

Perl API for magic interface, used by the C<PP> backend

=item L<KiokuDB>, L<Tangram>, L<Pixie>

=back
