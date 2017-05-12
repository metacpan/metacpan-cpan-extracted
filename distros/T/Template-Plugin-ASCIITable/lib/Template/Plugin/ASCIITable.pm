package Template::Plugin::ASCIITable;
use base 'Template::Plugin';
use Text::ASCIITable;
use vars qw($VERSION $AUTOLOAD);

$VERSION='0.2';

=head1 NAME

Template::Plugin::ASCIITable

=head1 SYNOPSIS

  [% USE ASCIITable %]
  blah
  [% ASCIITable.cols('a', 'b', 'c');
     ASCIITable.rows([1,2,3],['one','two','three']);
     ASCIITable.draw() %]

=head1 DESCRIPTION

This module allows you to use L<Text::ASCIITable> in your templates.

A plugin object will be instantiated with the directive:

  [% USE ASCIITable %]

You can pass a number of parameters to the constructor, for example:

  [% USE ASCIITable(cols => ['a','b','c'], show=>'rowline') %]

See L</Parameters> for details.

To obtain the table, you invoke the C<draw> method, to which you can
pass the same parameters:

  [% ASCIITable.draw(rows=>[[1,2,3],['one','two','three']]) %]

=head1 METHODS

=head2 C<new>

This is the plugin construtor. You should never call it directly: use
the C<USE> directive.

=cut

sub new {
  my ($class,$context,$params)=@_;
  my $self=bless {hide=>{rowline=>1}},$class;
  $self->handleParms(%$params) if $params;
  return $self;
}

=head2 C<draw>

This method invokes L<Text::ASCIITable> to obtain the textual
representation of the table, and returns it.

You can pass various parameters to it, see L</Parameters>.

=cut

sub draw {
  my ($self,@rest)=@_;
  $self->handleParms(@rest) if @rest;
  my $t=Text::ASCIITable->new({$self->_globals()});
  $t->setCols($self->_colnames());
  for my $c ($self->_colprops()) {
    $t->alignCol($c->{name},$c->{align}) if $c->{align};
    $t->alignColName($c->{name},$c->{nalign}) if $c->{nalign};
    $t->setColWidth($c->{name},$c->{width},$c->{widen}) if ($c->{width}||-1)>0;
  }
  for my $r ($self->_rows()) {
    $t->addRow($r)
  }
  my $ret=$t->draw($self->_style());
  my ($l,$r)=$self->_squeeze();
  $ret=~s/^.{$l}//mg if $l;
  $ret=~s/.{$r}$//mg if $r;

  $ret=~s/\n$//;
  return $ret;
}

my %paramSubs=(
               hide => \&hide,
               show => \&show,
               cols => \&cols,
               errors => \&errors,
               reporterrors => \&errors,
               allow => \&allow,
               deny => \&deny,
               alignheadrow => \&alignHeadRow,
               rows => \&rows,
               style => \&style,
);

=head1 Parameters

These parameters can be set in three ways:

=over 4

=item *

passing them to the constructor

=item *

passing them to the C<draw> call

=item *

setting them with individual method calls

=back

All three forms are case-insensitive: you can do

  [% USE t=ASCIITable(allow=>'HTML') %]
  [% t.Allow('html') %]
  [% t.draw(ALLOW=>'HtMl') %]

=cut

sub handleParms {
  my ($self,%params)=@_;
  for my $k (keys %params) {
    if (exists $paramSubs{lc($k)}) {
      $paramSubs{lc($k)}->($self,$params{$k});
    } else {
      _die("no such parameter $k");
    }
  }
  return;
}

=head2 C<hide>

This parameter accepts a list of names of features to hide. The
recognized names are:

=over 4

=item C<firstline>

The very first decoration line of the table, before the column names.

=item C<headrow>

The line containing the names of the columns.

=item C<headline>

The decoration line separating the column names from the data lines.

=item C<rowline>

The decoration line separating one data line from the next. I<Hidden
by default>.

=item C<lastline>

The very last decoration line, after all the data.

=back

Note: C<t.hide('headrow');t.hide('headline')> will cause I<both>
features to be hidden. See L</show>.

=cut

sub hide {
  my ($self,@what)=@_;
  if (@what==1 and ref($what[0]) eq 'ARRAY') {
    @what=@{$what[0]};
  }
  @{$self->{hide}}{grep {m{(headrow)|((head|first|last|row)line)}} map {lc $_} @what}=();
  return;
}

=head2 C<show>

This parameter does the opposite of C<hide>: sets the given features
to be shown.

Note: C<t.show('headrow');t.show('headline')> will cause I<both>
features to be shown. See L</hide>.

=cut

sub show {
  my ($self,@what)=@_;
  if (@what==1 and ref($what[0]) eq 'ARRAY') {
    @what=@{$what[0]};
  }
  delete @{$self->{hide}}{grep {m{(head(row|line))|((first|last|row)line)}} map {lc $_} @what};
  return;
}

=head2 C<errors>

Setting this to a true value will set the C<reportErrors> option (see
L<Text::ASCIITable>).

=cut

sub errors {
  my ($self,$val)=@_;
  $self->{errors}=$val;
  return;
}

=head2 C<allow>

This parameter accepts a list of markup names to allow inside the
cells. This in needed to let C<Text::ASCIITable> calculate the correct
column widths. The recognized markups are:

=over 4

=item C<ansi>

This will allow you to use ANSI escape sequences for things like
colors or baldface. This usually works only if you output to a
compliant terminal.

=item C<html>

This will allow you to use HTML tags. No check is performed on the
well-formedness of any such tag.

=back

Note: C<t.allow('html');t.allow('ansi')> will cause I<both>
markups to be recognized. See L</deny>.

=cut

sub allow {
  my ($self,@what)=@_;
  if (@what==1 and ref($what[0]) eq 'ARRAY') {
    @what=@{$what[0]};
  }
  @{$self->{allow}}{grep {m{ansi|html}} map {lc $_} @what}=();
  return;
}

=head2 C<deny>

This parameter does the opposite of C<allow>: ignores the given
markups inside cells, counting them as data.

Note: C<t.deny('html');t.deny('ansi')> will cause I<both>
markups to be ignored. See L</allow>.

=cut

sub deny {
  my ($self,@what)=@_;
  if (@what==1 and ref($what[0]) eq 'ARRAY') {
    @what=@{$what[0]};
  }
  delete @{$self->{allow}}{grep {m{ansi|html}} map {lc $_} @what};
  return;
}

=head2 C<alignHeadRow>

Sets the alignment for the column names. Can be one of:

=over 4

=item *

left

=item *

right

=item *

center

=item *

auto

=back

=cut

sub alignHeadRow {
  my ($self,$val)=@_;
  $self->{headrow}=$val;
  return;
}

sub _handleCols {
  my ($self,@colspec)=@_;
  if (@colspec==1 and ref($colspec[0]) eq 'ARRAY') {
    @colspec=@{$colspec[0]};
  }
  my %colpos=();
  my @cols=();
  for (@colspec) {
    if (ref $_) {
      push @cols,{name=>$_->[0],
                  align=>$_->[1],
                  width=>$_->[2],
                  widen=>$_->[3],
                  nalign=>$_->[4],
                 };
      $colpos{$_->[0]}=$#cols;
    } else {
      push @cols,{name=>$_};
      $colpos{$_}=$#cols;
    }
  }
  return (\@cols,\%colpos)
}

=head2 C<cols>

This parameter sets the names, and optionally some properties, of all
the columns in the table. To add columns to an existing table, use
the L</addCols> parameter (usually as a method).

This parameter accepts a list of column specifications. Each
specification can be:

=over 4

=item a single string

that becomes the name of the column, and width and alignment default
to 'auto'

=item an array reference

that contains, in order:

=over 8

=item *

the name

=item *

the alignment for the data, one of 'left', 'right', 'center', 'auto' (see
L<Text::ASCIITable/alignCol>)

=item *

the maximum width of the column, in characters (see
L<Text::ASCIITable/setColWidth>)

=item *

whether to force the width of the column, a boolean (see
L<Text::ASCIITable/setColWidth>, the last parameter)

=item *

the name alignment (see L<Text::ASCIITable/alignColName>)

=back

=back

Note: this sets I<all of the columns>. C<t.cols('a','b');t.cols('c')>
will result in a table with I<only 1> column. See L</addCols>.

=cut

sub cols {
  my $self=shift;
  ($self->{cols},$self->{colpos})=$self->_handleCols(@_);
  return;
}

=head2 C<addCols>

This parameter works like C<cols>, but adds the given columns to the
existing ones, instead of replacing them. So
C<t.cols('a','b');t.addCols('c')> will result in a table with 3 columns.

=cut

sub addCols {
  my $self=shift;
  my ($cols,$colpos)=$self->_handleCols(@_);
  push @{$self->{cols}},@$cols;
  @{$self->{colpos}}{keys %$colpos}=values %$colpos;
  return;
}

=head2 C<rows>

This parameter accepts a list of array references, one per row. Each
row must have one scalar element per each column that will be
produced.

Note that, because of the way this plugin works, you can do something
like: 

  [% USE t=ASCIITable(cols=>['a','b']);
     t.rows([1,2,3],[4,5,6]);
     t.addCols('c');
     t.draw() %]

And it will print a 3x2 table.

Note: this sets I<all of the rows>.
C<t.rows([1,2,3],[4,5,6]);t.rows([7,8,9])>
will result in a table with I<only 1> row. See L</addRows>.

=cut

sub rows {
  my ($self,@rows)=@_;
  if (@rows==1 and ref($rows[0]) eq 'ARRAY') {
    @rows=@{$rows[0]};
  }
  $self->{rows}=[@rows];
  return;
}

=head2 C<addRows>

This parameter works like C<rows>, but adds the given rows to the
existing ones, instead of replacing them. So
C<t.rows([1,2,3],[4,5,6]);t.addRows([7,8,9])>
will result in a table with 3 rows.

=cut

sub addRows {
  my ($self,@row)=@_;
  if (@row==1 and ref($row[0]) eq 'ARRAY') {
    @row=@{$row[0]};
  }
  push @{$self->{rows}},[@row];
  return;
}

my %styles=(
            'default'=>
            {lines=>undef,
             globals=>{hide=>'rowline'},
            },
            'rest-simple'=>
            {lines=>[
                     ['<','>','=',' '],
                     ['<','>',' '],
                     ['<','>','=',' '],
                     ['<','>',' '],
                     ['<','>','=',' '],
                     ['<','>','-',' '],
                     1,1,
                    ],
             globals=>{hide=>'rowline'},
            },
            'rest-grid'=>
            {lines=>[
                     ['+','+','-','+'],
                     ['|','|','|'],
                     ['+','+','=','+'],
                     ['|','|','|'],
                     ['+','+','-','+'],
                     ['+','+','-','+'],
                     0,0,
                    ],
             globals=>{show=>'rowline'},
            },
           );

=head2 C<style>

This parameter sets the draw style for the table. You can set it to a
list of array references, or to a style name.

If you pass it a list, it can have 5, 6, or 8 elements. The first 6
elements are interpreted in the same way as the parameters of
C<Text::ASCIITable::draw> (see L<Text::ASCIITable/Custom tables>). The
last two, which default to 0, are the number of columns to remove on
the left- and right-hand side of the generated table; this is used to
have tables without vertical borders.

If you pass it a style name, it must be one of the following:

=over 4

=item C<default>

this is the default C<Text::ASCIITable> style:

  .--------------------------.
  | one | two | three | four |
  +-----+-----+-------+------+
  | one | one | one   | one  |
  | two | two | two   | two  |
  '-----+-----+-------+------'

=item C<rest-simple>

this is the "simple table" style as used in reStructuredText:

 ===== ===== ======= ======
  one   two   three   four 
 ===== ===== ======= ======
  one   one   one     one  
  two   two   two     two  
 ===== ===== ======= ======

If you give C<show('rowline')> you get:

 ===== ===== ======= ======
  one   two   three   four 
 ===== ===== ======= ======
  one   one   one     one  
 ----- ----- ------- ------
  two   two   two     two  
 ===== ===== ======= ======

Note that there is no blank space on either side.

=item C<rest-grid>

this is the "grid table" style as used in reStructuredText:

 +-----+-----+-------+------+
 | one | two | three | four |
 +=====+=====+=======+======+
 | one | one | one   | one  |
 +-----+-----+-------+------+
 | two | two | two   | two  |
 +-----+-----+-------+------+

=back

=cut

sub style {
  my ($self,$style)=@_;
  if (ref $style eq 'ARRAY') {
    if (@$style==6) {
      $self->{style}=[@$style,0,0]
    } elsif (@$style==5) {
      $self->{style}=[@$style,[],0,0]
    } elsif (@$style==8) {
      $self->{style}=[@$style]
    } else {
      _die('Wrong style specification')
    }
  } elsif (exists $styles{lc $style}) {
    $self->{style}=$styles{lc $style}->{lines};
    $self->handleParms(%{$styles{lc $style}->{globals}});
  } else {
    _die("No such style $style");
  }
}

sub AUTOLOAD {
  return if $AUTOLOAD=~/:?DESTROY$/;
  if (exists $paramSubs{lc($AUTOLOAD)}) {
    goto &{$paramSubs{lc($AUTOLOAD)}};
  } else {
    _die("no such method $AUTOLOAD")
  }
}

sub _globals {
  my ($self)=@_;
  my @ret=();
  push @ret,'hide_HeadRow',1 if exists $self->{hide}{headrow};
  push @ret,'hide_HeadLine',1 if exists $self->{hide}{headline};
  push @ret,'hide_FirstLine',1 if exists $self->{hide}{firstline};
  push @ret,'hide_LastLine',1 if exists $self->{hide}{lastline};
  push @ret,'allowANSI',1 if exists $self->{allow}{ansi};
  push @ret,'allowHTML',1 if exists $self->{allow}{html};
  push @ret,'reportErrors',$self->{errors} if $self->{errors};
  push @ret,'alignHeadRow',$self->{headrow} if $self->{headrow};
  push @ret,'drawRowLine',1 unless exists $self->{hide}{rowline};
  return @ret;
}

sub _colprops {
  my ($self)=@_;
  return @{$self->{cols}};
}
sub _colnames {
  my ($self)=@_;
  return map {$_->{name}} @{$self->{cols}};
}
sub _rows {
  my ($self)=@_;
  return ($self->{rows}?@{$self->{rows}}:());
}

sub _style {
  my ($self)=@_;
  return ($self->{style}?@{$self->{style}}[0..5]:());
}
sub _squeeze {
  my ($self)=@_;
  return ($self->{style}?@{$self->{style}}[6,7]:(0,0));
}

sub _die {
  die (Template::Exception->new('ASCIITable',$_[0]))
}

=head1 TODO

Better tests?

=head1 BUGS

None known so far. If you find any, please report them using
rt.cpan.org or e-mail. It would be great if you could provide a simple
test case that exercises the bug.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 dakkar <dakkar@thenautilus.net>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

1;
