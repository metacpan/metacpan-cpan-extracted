package Ref::Store::Dumper;
use strict;
use warnings;
use Scalar::Util qw(isweak looks_like_number);
use Log::Fu;

our $IndentChar = '    ';

sub new {
    my $cls = shift;
    my $self = { Indent => 0, Buf => "" };
    bless $self, $cls;
    return $self;
}

sub print {
    my $self = shift;
    $self->{Buf} .=  $IndentChar x $self->{Indent};
    my $fmt = shift @_;
    $self->{Buf} .= sprintf($fmt, @_);
    $self->{Buf} .= "\n";
}

sub fmt_ptr {
    shift @_ if @_ == 2;
    my $s = "";
    my $ptr = $_[0];
    if (ref $ptr || looks_like_number($ptr)) {
        $s .= sprintf("[%d 0x%x]", $ptr+0, $ptr+0);
    }
    if(ref $ptr) {
        $s .= sprintf(" SV=0x%x WEAK=%d ISA=%s", \$_[0], isweak($_[0]), ref $ptr);
    } elsif(!looks_like_number($ptr)) {
        $s .= $ptr;
    }
    return $s;
}

sub flush {
    my $self = shift;
    print $self->{Buf};
    $self->{Buf} = "";
}

sub iprint {
    my ($self,@pargs) = @_;
    $self->{Indent}++;
    $self->print(@pargs);
    $self->{Indent}--;
}

sub hdr {
    my ($self,@pargs) = @_;
    my $old_indent = $self->{Indent};
    $self->{Indent}-- if $old_indent;
    $self->{Buf} .= "\n";
    $self->print(@pargs);
    $self->{Buf} .= "\n";
    $self->{Indent}++;
}

sub dump {
	my ($self,$table) = @_;
    $self->hdr("Values");
	while ( my($v,$rhash) = each %{$table->reverse}) {
        $self->print("V: %s", $self->fmt_ptr($v));
		while (my ($lk,$lo) = each %$rhash) {
            $self->iprint("L: %s, %s", $lo->kstring,
						  $self->fmt_ptr($rhash->{$lk}));
		}
	}
	
    $self->hdr("Forward Lookups");
    
    	
	while ( my ($k,$vobj) = each %{$table->forward}) {
        $self->iprint("L: %s", $self->fmt_ptr($k));
        $self->{Indent}++;
        $self->iprint("V: %s", $self->fmt_ptr($table->forward->{$k}));
        $self->{Indent}--;
	}
    
    $self->hdr("Scalar to key object mappings");
    
	while (my ($ustr,$ko) = each %{$table->scalar_lookup}) {
        if(!defined $ko) {
            $self->iprint("UKEY=%s, KO=undef", $self->fmt_ptr($ustr));
            next;
        }
        $self->iprint("UKEY=%s KO=%s",
            $self->fmt_ptr($ustr),
			$self->fmt_ptr($table->scalar_lookup->{$ustr}));
		
        if($ko->can("dump")) {
            $self->{Indent}++;
            $ko->dump($self);
            $self->{Indent}--;
        }
	}
    
    $self->hdr("Attribute mappings");
    while (my ($astr,$aobj) = each %{$table->attr_lookup}) {
        $self->iprint("ASTR=%s ATTR=%s", $astr,
					  $self->fmt_ptr($table->attr_lookup->{$astr}));
        if($aobj->can("dump")) {
            $self->{Indent}++;
            $aobj->dump($self);
            $self->{Indent}--;
        }
    }
}

1;