use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use t::scan::Util;

test(<<'TEST'); # CHORNY/Win32API-File-0.1203/File.pm
    my $tied = !defined($^]) || $^] < 5.008
                       ? eval "tied *{$file}"
                       : tied *{$file};
TEST

test(<<'TEST'); # JV/mmds-1.902/MMDS/Common.pm
sub ::loadpkg {
    my ($pkg, $package) = @_;
    $package ||= caller;
    $pkg = $package . "::" . $pkg unless $pkg =~ /::/;
    $pkg =~ s/::::/::/g;
    warn("Loading: $pkg\n") if $::trace;
    my $ok = eval("require $pkg");
    die(@$) if @$;
    die("Error loading $pkg\n") unless $ok;
}
TEST

test(<<'TEST'); # MSISK/Net-Nmsg-0.15/lib/Net/Nmsg/Layer.pm
sub _fake_stat {
  my $self = shift;
  return unless $self->opened;
  return 1 unless wantarray;
  return (
    undef, # dev
    undef, # ino
    0666,  # mode
    1,     # links
    $>,    # uid
    $),    # gid
    undef, # did
    0,     # size
    undef, # atime
    undef, # mtime
    undef, # ctime
    0,     # blksize
    0,     # blocks
  );
}
TEST

test(<<'TEST'); #
sub next {
    my $self = shift;
    my @objects = @{${$self}[1]};
    my @return;
    
    local @_h = @_;  
    my $pre = $self->pre;
    if (defined($pre)) {	
      @_h = &{$pre}($self, @_);
    }
    my $status = 1;
    my $obj;
    local @_s;
  OBJ:foreach $obj (@objects) { # sub-objects
      @return = $$obj->next(@_h);
      if (not $$obj->status) {
	$status = 0;
	last OBJ;
      } else {
	push(@_s, @return) if $#return >= 0;
      }
    }
    if ($status) { 
      $self->status(1);
      my $post = $self->post;
      if (defined($post)) {
	&{$post}($self, @_s);
      } else {
	@_s;
      }
    } else {
      $self->status(0);
      ();
    }
}
TEST

test(<<'TEST'); # SPROUT/CSS-DOM-0.16/lib/CSS/DOM/PropertyParser.pm
  my $list = shift @'_;
  my $sep = @$list <= 1 ? '' : do {
   my $range_start = $$list[0][4];
   my $range_end = $$list[1][4] - length($$list[1][4]) - 1;
   my(undef,$stokens) = _space_out(
    substr($types, $range_start-1, $range_end-$range_start+3),
    [@$tokens[$range_start-1...$range_end+1]]
   );
   join "", @$stokens[1...$#$stokens-1];
  };
  return $css, "CSS::DOM::Value::List",
   separator => $sep, css => $css,
   values => [ map {
    my @args = _make_arg_list(
                   @$_[0...3]
    );
    shift @args, shift @args;
    \@args
   } @$list ];
TEST

test(<<'TEST'); # MAKAROW/Tk-TM-0.53/lib/Tk/TM/DataObject.pm
 foreach (my $i=@[; $i<=$colcount; $i++) {
   push(@$colspecs, ['','Entry']);
 }
TEST

done_testing;
