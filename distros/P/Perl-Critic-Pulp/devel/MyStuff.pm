# Copyright 2009, 2011 Kevin Ryde.

# MyStuff.pm is shared by various distributions.
#
# MyStuff.pm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyStuff.pm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

package MyStuff;
use 5.010;
use strict;
use warnings;
use Text::Tabs;

#my $verbose = 0;

sub line_at_pos {
  my ($str, $pos) = @_;
  my $start = (rindex ($str, "\n", $pos) || -1) + 1;
  my $end = (index ($str, "\n", $pos) || length($str)-1) + 1;
  return substr($str, $start, $end - $start);
}

sub pos_to_line_and_column {
  my ($str, $pos) = @_;
  $str = substr ($str, 0, $pos);
  my $nlpos = rindex ($str, "\n");
  my $lastline = substr ($str, $nlpos+1);
  $lastline = Text::Tabs::expand ($lastline);
  my $colnum = 1 + length ($lastline);
  my $linenum = 1 + scalar($str =~ tr/\n//);
  return ($linenum, $colnum);
}



package Iterator::Simple::FileUniq;
sub new {
  my ($class, $it) = (shift, shift);
  my $fu = FileUniq->new (@_);
  return Iterator::Simple::iterator
    (sub {
       my $filename;
       while (defined (my $filename = $it->next)) {
         last if $fu->uniq ($filename);
       }
     });
}

package Locator;
sub new {
  my ($class, @args) = @_;
  open my $fh, '-|', 'locate', '-0', '--', @args or die;
  return bless { fh => $fh,
               }, $class;
}
sub next {
  my ($self) = @_;
  my $fh = $self->{'fh'};
  my $filename;
  {
    local $/ = "\0";
    $filename = <$fh>;
    if (defined $filename) {
      chomp $filename;
    }
  }
  return $filename;
}

package Locator::BinScripts;
sub new {
  my ($class, $type) = @_;
  return bless { 'type' => $type,
                 'locator' => Locator->new ('/bin/*',
                                            '/usr/bin/*',
                                            '/usr/local/bin/*',
                                            '/usr/local/bin2/*',
                                           ) }, $class;
}
sub next {
  my ($self) = @_;
  my $type = $self->{'type'};
  for (;;) {
    my $filename = $self->{'locator'}->next // return undef;
    my ($fh, $buf);
    if (open($fh,'<',$filename)
        && read($fh,$buf,80)
        && $buf =~ m{^#![a-z0-9/]*/$type([ \t]|$)}) {
      return $filename;
    }
  }
}

package Locator::Concat;
sub new {
  my ($class, @locators) = @_;
  return bless { 'locators' => \@locators }, $class;
}
sub next {
  my ($self) = @_;
  my $locators = $self->{'locators'};
  for (;;) {
    @$locators or return undef;
    my $filename = $locators->[0]->next;
    if (defined $filename) { return $filename; }
    shift @$locators;
  }
}

1;
__END__
my @files = split /\n/, `locate \*.t \*.pm \*.pl`;
@files = grep {-f $_} @files;

@files = uniq_by_func (\&stat_dev_ino, @files);
sub uniq_by_func {
  my $func = shift;
  my %seen;
  return grep { $seen{$func->($_)}++ == 0 } @_;
}
sub stat_dev_ino {
  my ($filename) = @_;
  my ($dev, $ino) = stat ($filename);
  return "$dev,$ino";
}

print "look at ",scalar(@files)," files\n";

