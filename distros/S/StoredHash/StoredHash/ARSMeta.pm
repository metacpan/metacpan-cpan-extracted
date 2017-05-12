package StoredHash::ARSMeta;

use ARS;
use Data::Dumper;

use strict;
use warnings;

sub nofilter {1;} # To Storehash ?
#=head2 meta($shp, %opts)
#Get Information about Remedy Schema.
#=cut
# ars_GetListSchema(ctrl, [changedSince, schemaType, name])
sub meta {
   my ($p, %c) = @_;
   if (!$p->isa('StoredHash::ARS')) {die("StoredHash not passed");}
   my $fcb = $c{'filter'} || sub {
      my ($h) = @_;
      my $fn = $h->{'fieldName'};
      if ($fn =~ /^zTmp/i) {return(0);}
      if ($fn =~ /^btn:/) {return(0);}
      #if ($fn =~ /^btn:/) {return(0);}
      #if ($fn =~ /^TXT:/i) {return(0);}
      if ($h->{'dataType'} eq 'control') {return(0);}
      #if ($e->{'dataType'} eq 'trim') {return(0);} # Fset ?
      1;
   };
   my $debug = $p->{'debug'};
   my ($sc, $ctrl) = @$p{'table', 'dbh'};
   if (!$sc || !$ctrl) {die("Tab or ctl Missing ()\n");}
   # OR StoredHash::ARSMeta->can($fcb);
   if (ref($fcb) ne 'CODE') {die("Filter NOT Code");}
   
   # Attr - ALl or explicit from 'attr'
   my $attr = $c{'attr'};
   if (ref($attr) eq 'ARRAY') {}
   # 
   else {
      #my %fld = ars_GetFieldTable($ctrl, $sc);
      #my %fldr = reverse(%fld);
      # changedsince=0 ... fieldtype
      if ($debug) {print(STDERR "Calling ars_GetListField($ctrl, '$sc')");}
      #  [ERROR] Cannot open catalog; Message number = 161 () (ARERR #161)
      my @fld = ars_GetListField($ctrl,$sc);
      if ($ars_errstr) {die("Error with ars_GetListField(): $ars_errstr");}
      if ($debug) {print(Dumper(\@fld));}
      $attr = \@fld;
      
   }
   my $acnt = scalar(@$attr);
   if ($debug) {print(STDERR "$acnt attrs for '$sc'\n");}
   ########
   my @fattr = ();
   my $skipcnt = 0;
   for my $aid (@$attr) {
      
      my $h = ars_GetField($ctrl, $sc, $aid);
      #my $fn = $h->{'fieldName'};
      # print("SKIP: $fn\n"); ~28%
      if (!$fcb->($h)) {$skipcnt++;next;}
      if ($c{'std'}) {$h = stdmeta($h, 'schema' => $sc);}
      #push(@fattr, $h);
      push(@fattr, $h);
   }
   if ($p->{'debug'}) {print(STDERR "$skipcnt attrs skipped by filter\n");}
   #DEBUG:print(Dumper(\@fattr));
   #DEBUG:print("Skipped $skipcnt (Valid: ".scalar(@fattr).")\n");
   return(\@fattr);
}

# Helper for meta() to modify Field Information.
sub stdmeta {
   my ($h, %c) = @_;
   my $sc = $c{'schema'} || 'Unknown_'.time();
   no warnings;
   delete($h->{'displayInstanceList'});
   # Owners
   delete($h->{'owner'});delete($h->{'lastChanged'});
   delete($h->{'timestamp'});
   if ($h->{'helpText'}) {$h->{'helpText'} =~ s/\s+$//;}
   #DEBUG:print(Dumper($h));
   # 'helpText'
   # 
   # $h->{'option'} 1..4
   # - 1 limit: dataType=4(char) maxLength 254 'fieldName' => 'Submitted By'
   #   sometimes: 'dataType' => 6, has limit.enumLimits.regularList 'fieldName' => 'Status'
   # - 2 (sometimes E)
   #    sometimes no enum, 'maxLength' => 254,  'fieldName' => 'Assignee Login Name'
   #    no enuym, 'maxLength' => 30,'dataType' => 4, 'fieldName' => 'Assignee Group'
   #    example: 'fieldName' => 'Phone Number'
   # - 3 limit: dataType=4(char) no emums 'fieldName' => 'Case ID+'
   #     sometimes limit: undef 'fieldName' => 'Arrival Time'
   # - 4 'limit' => undef, 'fieldName' => 'Submit' 'dataType' => 'control',
   #   Seems to be controls only ('fieldName' => 'Query''defaultVal' => undef,)
   #   Sometimes limit => {...} 'fieldName' => 'Search Bar' 'dataType' => 'char',
   #   'fieldName' => 'Results List' 'numColumns' => 12, 'dataType' => 'table',
   # Control in Remedy means button (action), these buttons have 'limit' => undef
   # 'dataType' => 'table', Means listview
   # 'limit'->'schema' => '@', means current schema (for datatype table)
   #  'limit'->'qualifier' = {}
   #   'limit'->'charmenu' = "HDP:HPD-Inventory Users"; gives optsrc 'fieldName' => 'User Name_INV'
   # Could collect associated / related tables from 'limit'.'charMenu'
   #  (Example 'fieldName' => 'Category')
   # 'limit'->'match' = 'equal' behaviour on search ?
   # 'dataType' => 'diary', Child ent / events on entry
   # dataType on 3 levels 
   # - Top: time,char,integer,real,enum,
   #        control,table,diary,column,page,trim,view,currency,page_holder
   # - $h->{'limit'}{'dataType'}: 2 (integ.),3(real),4(char),6(enum),33(table)
   #   34(column),42(view)
   # ('dataType' => 6, 'enumLimits')
   # 'dataType' => 'trim', in fielname: 'fieldName' => 'box_top' (fieldset)
   # 'defaultVal' 'fieldName' 'fieldId'
   # diary examples: work Log ,'Audit Trail'
   # Limit / Constrain
   my $lim = $h->{'limit'};
   my $opts;
   #'createMode' => 'protected',
   my $uit = 'textinput'; # Maybe after all others ...
   my $uil = 16;
   # Enum opts
   my $optse = $lim->{'enumLimits'}->{'regularList'};
   # Schema ?
   #my $optss = $lim->{'enumLimits'}->{'schema'}; # ??? # Self Ref ?
   # Fk opts
   my $optsf = $lim->{'charMenu'};
   if    ($optsf) {$opts = [$optsf,'?','?'];$uit = 'optionmenu';}
   elsif ($optse) {$opts = $optse;$uit = 'optionmenu';}
   else  {$opts = undef;}
   # colLength for col maxLength for prim.
   my $dlen = $lim->{'maxLength'} || $lim->{'colLength'}; # || 16;
   #if ($opts) {}
   #$h->{'fieldMap'}->{'fieldType'};
   # ^@USER^@'
   #if ($h->{'defaultVal'} =~ //) {}
   # UIT Overr.
   # Many Date field configured as 'char'
   # || $h->{'fieldName'} =~ /Date/
   if ($h->{'dataType'} =~ /time/) {$uit = 'timewidget';$uil = 20;$dlen = 20;}
   my %ma;
   # Map to nat
   @ma{'tabname','attrname','alias','dtype','dlen','uitype','uilen',
      'defval',
      'optsrc',} =
   @$h{'','fieldId','fieldName','dataType','','','',
      'defaultVal',
      '',};
   my %tt = ('real' => 'float', 'time' => 'datetime',); #'' => '',
   #if (my $nt = $tt{$ma{'dtype'}} ) {$ma{'dtype'} = $nt;}
   @ma{'tabname','dlen','uitype','uilen','optsrc',} = ($sc, $dlen, $uit, $uil, $opts);
   return(\%ma);
}

# Doc: (in 'limit'.charmenu
# Category: HPD:HelpDeskCategory
# Type: SHR:Type
# Item: SHR:Item
#'prop' => 230,
#            'value' => '6\\0\\New\\1\\Assigned\\2\\Work In Progress\\3\\Pending\\4\\Resolved\\5\\Closed',
#            'valueType' => 'char'
1;
################## JUNK ################
#if (0) {
   # my $arsconn = new ARS(-server => $rcred->{'host'}, -username => $rcred->{'uid'}, 
   #   -password => $rcred->{'pwd'});
   # my $f = $arsconn->openForm(-form => $sc);
   # delete($f->{'connection'});
#   }

