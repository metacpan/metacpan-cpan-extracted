package orac_Oracle;
use strict;

@orac_Oracle::ISA = qw{orac_Base};

my $Block_Size;

my $sql_slider;
my $sql_row_count;
my $sql_browse_arr;
my $w_orig_sql_string;
my $keep_tablespace;
my $l_sel_str;

my $expl_butt;
my $gen_sc;
my $gc;
my $max_row;
my $min_row;
my $uf_type;

my @o_ih;
my @sql_entry;
my @i_uc;
my @i_ac;
my @lrg_t;
my @ih;
my @dsc_n;
my @tot_ind_ar;

my $ind_name;
my $t_n;
my $tot_i_cnt;
my $ind_bd_cnt;

my $ary_ref;
my $w;
my $m_t;

my $own;
my $obj;

my @w_holders;
my @w_titles;
my @w_explain;

sub new
{
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my ($l_window, $l_text) = @_;

   my $self  = orac_Base->new("Oracle", $l_window, $l_text);

   bless($self, $class);
   return $self;
}

sub init1 {
   my $self = shift;

   my($l_instance) = @_;

   # Set all environmental variable required for DBD::Oracle

   $main::ENV{TWO_TASK} = $l_instance;
   $main::ENV{ORACLE_SID} = $l_instance;
}

sub init2 {

   my $self = shift;

   $self->{Database_conn} = $_[0];
   $self->Dump;

   # Get the block size, as soon as we
   # logon to a database.  Saves us having to 
   # continually find it out again, and again.

   my $cm = $self->f_str('get_db','1');
   print STDERR "init2: cm >$cm<\n" if ($main::debug > 0);

   my $sth = $self->{Database_conn}->prepare( $cm ) || 
                die $self->{Database_connector}->errstr; 
   $sth->execute;
   ($Block_Size) = $sth->fetchrow;
   $sth->finish;

   # Enable the PL/SQL memory area, for this 
   # database connection

   $self->{Database_conn}->func(1000000,'dbms_output_enable');
}

################ Database dependent code functions below here ##################

sub tune_wait {
   my $self = shift;

   # Works out if anything is waiting in the database

   my $cm = $self->f_str( 'tune_wait' , '1' );
   $self->show_sql( $cm , $main::lg{sess_wt_stats} );
   $self->about_orac('txt/Oracle/tune_wait.1.txt');

}

sub tune_pigs {
   my $self = shift;

   # This function gives you two differing reports
   # which measure the Shared Pool disk reads
   # for various SQL statements in the library

   my($type_flag)=@_;

   my $title;

   if($type_flag == 1){
      # If type 1, then we only want the highest 
      # summarised readings
      $title = $main::lg{mem_hogs1};
   }
   elsif($type_flag == 2){
      # If type 1, then we only want the highest 
      # summarised readings
      $title = $main::lg{mem_hogs2};
   }
   # Report for finding SQL monsters

   my $cm = $self->f_str( 'tune_pigs' , $type_flag );
   $self->show_sql( $cm , $title );

}

sub who_what {

   my $self = shift;

   # Works out who is holding whom, so we can unblock
   # needless locking.

   my ($flag,$param1,$param2,$param3) = @_;

   print STDERR "who_what: param1 >$param1<\n" if ($main::debug > 0);
   print STDERR "who_what: param2 >$param2<\n" if ($main::debug > 0);
   print STDERR "who_what: param3 >$param3<\n" if ($main::debug > 0);

   my $title;

   if($flag == 1){
      $title = "$param1 $main::lg{investgn}";
   } elsif ($flag == 2){
      $title = "$param2";
   }
   my $d = $self->{Main_window}->DialogBox(  -title=>$title  );

   my $loc_text = $d->Scrolled('Text',
                               -wrap=>'none',
                               -cursor=>undef,
                               -foreground=>$main::fc,
                               -background=>$main::bc
                              );

   $loc_text->pack(-expand=>1,-fil=>'both');

   # For just a short while,
   # set the default output text window to this one

   tie (*main::TEXT, 'Tk::Text', $loc_text);
   my $old_self_text = $self->{Text_var};
   $self->{Text_var} = $loc_text;

   my $cm;

   if( $flag == 1 ){

      $cm = $self->f_str('who_what','1');
      $self->show_sql(   $cm,
                         $main::lg{hold_sql},
                         $param1,
                         $param2,
                         $param3
                     );

   } elsif ( $flag == 2 ){

      $cm = $self->f_str('statter','1');

      print STDERR "who_what: cm     >\n$cm\n<\n" if ($main::debug > 0);
      print STDERR "who_what: title  >$title<\n" if ($main::debug > 0);
      print STDERR "who_what: param1 >$param1<\n" if ($main::debug > 0);

      $self->show_sql(   $cm,
                         $title,
                         $param1
                        );

   }
   my $b = $loc_text->Button(  -text=>$main::ssq,
                               -command=>sub{  $self->see_sql($d,$cm)  }
                            );

   # Now tie the main screen back again

   $self->{Text_var} = $old_self_text;
   tie (*main::TEXT, 'Tk::Text', $self->{Text_var});

   $d->Show;

}

sub all_stf {
   my $self = shift;

   # Takes particular PL/SQL statements,
   # and generates DDL to recreate ALL of a 
   # particular object in the database.

   my($module, $mod_number, $mod_binds) = @_;

   print STDERR "all_stf: module     >$module<\n" if ($main::debug > 0);
   print STDERR "all_stf: mod_number >$mod_number<\n" if ($main::debug > 0);
   print STDERR "all_stf: mod_binds  >$mod_binds<\n" if ($main::debug > 0);

   my $cm = $self->f_str($module, $mod_number);

   print STDERR "all_stf: cm         >\n$cm\n<\n" if ($main::debug > 0);

   my $sth = $self->{Database_conn}->prepare($cm) || 
                die $self->{Database_conn}->errstr; 
   my $i;
   for ( $i = 1 ; $i <= $mod_binds ; $i++ ){
      $sth->bind_param($i,'%');
   }
   $sth->execute;

   $i = 0;
   my $ls;
   while($i < 20000){
      $ls = scalar $self->{Database_conn}->func('dbms_output_get');
      if ((!defined($ls)) || (length($ls) == 0)){
         last;
      }
      $self->{Text_var}->insert('end', "$ls\n");
      $i++;
   }

   $self->see_plsql($cm);

}
sub orac_create_db {
   my $self = shift;

   # Generates a script with which you can
   # completely regenerate the skeleton of your
   # database

   my ($oracle_sid,$dum) = split(/\./, $main::v_db);
   my $cm = $self->f_str('orac_create_db','1');
   my $sth = $self->{Database_conn}->prepare( $cm ) || 
                die $self->{Database_conn}->errstr; 
   $sth->bind_param(1,$oracle_sid);
   $sth->execute;

   my $j = 0;
   my $full_list;

   while($j < 10000){
      $full_list = scalar $self->{Database_conn}->func('dbms_output_get');
      if ((!defined($full_list))|| (length($full_list) == 0)){
         last;
      }
      $self->{Text_var}->insert('end', "$full_list\n");
      $j++;
   }
   $self->see_plsql($cm);
}
sub selected_error {

   my $self = shift;

   # Pumps out information on a particular error

   my ($err_bit) = @_;
   my ($owner,$object) = split(/\./, $err_bit);

   $self->f_clr( $main::v_clr );
   $self->show_sql( $self->f_str( 'selected_error' , '1' ),
                    "$main::lg{comp_errs_for} $err_bit",
                    $owner,
                    $object
                  );
}

sub univ_form { 

   my $self = shift;

   my $w; # For small button window generation

   # A complex function for generating on-the-fly Forms
   # for viewing database information

   my $loc_d;

   ($loc_d,$own,$obj,$uf_type) = @_;

   print STDERR "\nuniv_form: loc_d   >$loc_d<\n" if ($main::debug > 0);
   print STDERR "univ_form: own     >$own<\n" if ($main::debug > 0);
   print STDERR "univ_form: obj     >$obj<\n" if ($main::debug > 0);
   print STDERR "univ_form: uf_type >$uf_type<\n\n" if ($main::debug > 0);

   $m_t = "$main::lg{form_for} $obj";

   my $bd = $loc_d->DialogBox(  -title=>$m_t,
                                -buttons=>[ $main::lg{exit} ]
                             );

   my $uf_txt;

   if ($uf_type eq 'index'){
      $uf_txt = "$own.$obj, $main::lg{sel_cols}";
   } else {
      $uf_txt = "$main::lg{prov_sql} $main::lg{sel_info}";
   }
   $bd->Label(-text=>$uf_txt,-anchor=>'n')->pack();

   my $t = $bd->Scrolled('Text',
                         -height=>16,
                         -wrap=>'none',
                         -cursor=>undef,
                         -foreground=>$main::fc,
                         -background=>$main::bc
                        );

   my $cm = $self->f_str('selected_dba','1');
   my $sth = $self->{Database_conn}->prepare( $cm ) || 
                die $self->{Database_conn}->errstr;
   $sth->bind_param(1,$own);
   $sth->bind_param(2,$obj);
   $sth->execute;

   my @h_t = (  $main::lg{i_col},
                $main::lg{i_sel_sql},
                $main::lg{i_dat_typ},
                $main::lg{i_ord}
             );

   my $i;

   for $i (0..3){
      unless (($uf_type eq 'index') && ($i == 2)){
         if ($i == 3){
            $w = $t->Entry(-textvariable=>\$h_t[$i],-cursor=>undef,-width=>3);
         } else {
            $w = $t->Entry(-textvariable=>\$h_t[$i],-cursor=>undef);
         }

         $w->configure(-background=>$main::fc,
                       -foreground=>$main::ec);

         $t->windowCreate('end',-window=>$w);
      }
   }
   $t->insert('end', "\n");

   my @c_t;
   my @t_t;
   $ind_bd_cnt = 0;

   my @res;

   while (@res = $sth->fetchrow) {
      $c_t[$ind_bd_cnt] = $res[0];
      $w = $t->Entry(-textvariable=>\$c_t[$ind_bd_cnt],-cursor=>undef);
      $t->windowCreate('end',-window=>$w);

      unless ($uf_type eq 'index'){

         $sql_entry[$ind_bd_cnt] = "";

         $w = $t->Entry(   -textvariable=>\$sql_entry[$ind_bd_cnt],
                           -cursor=>undef,
                           -foreground=>$main::fc,
                           -background=>$main::ec
                       );

         $t->windowCreate('end',-window=>$w);

      }
      $t_t[$ind_bd_cnt] = "$res[1] $res[2]";

      $w = $t->Entry( -textvariable=>\$t_t[$ind_bd_cnt],
                      -cursor=>undef);

      $t->windowCreate('end',-window=>$w);

      $i_ac[$ind_bd_cnt] = "$res[0]";

      $i_uc[$ind_bd_cnt] = 0;

      $w = $t->Checkbutton( -variable=>\$i_uc[$ind_bd_cnt],
                            -relief=>'flat');

      $t->windowCreate('end',-window=>$w);

      $t->insert('end', "\n");
      $ind_bd_cnt++;
   }
   $ind_bd_cnt--;
   $sth->finish;

   $t->configure( -state=>'disabled' );

   $t->pack( -expand =>1,
             -fill=>'both'
           );

   my $bb = $bd->Frame->pack( -side=>'bottom',
                              -before=> $t
                            );

   if ($uf_type eq 'index'){
      $uf_txt = 'Build Index';
   } else {
      $uf_txt = $main::lg{sel_info};
   }

   $bb->Button( -text=>$uf_txt,
                -command=>sub{ $bd->Busy;
                               $self->selector($bd,$uf_type);
                               $bd->Unbusy}
              )->pack (-side=>'right', 
                       -anchor=>'e');

   $bd->Show;
}

sub selector {

   my $self = shift;

   # User may wish to narrow search for info, down to 
   # a particular set of rows, and order these rows.
   # This function allows them to do that.

   my($sel_d,$uf_type) = @_;

   if ($uf_type eq 'index'){
      $self->build_ord($sel_d,$uf_type);
      return;
   }
   $l_sel_str = ' select ';

   my $i;

   for $i (0..$ind_bd_cnt){
      if ($i != $ind_bd_cnt){
         $l_sel_str = $l_sel_str . "$i_ac[$i], ";
      } else {
         $l_sel_str = $l_sel_str . "$i_ac[$i] ";
      }
   }

   $l_sel_str = $l_sel_str . "\nfrom ${own}.${obj} ";

   my $flag = 0;
   my $last_one = 0;

   for $i (0..$ind_bd_cnt){
      if ($i_uc[$i] == 1){
         $flag = 1;
         $last_one = $i;
      }
   }

   my $where_bit = "\nwhere ";
   for $i (0..$ind_bd_cnt){
      my $sql_bit = $sql_entry[$i];
      if (defined($sql_bit) && length($sql_bit)){
         $l_sel_str = $l_sel_str . $where_bit . "$i_ac[$i] $sql_bit ";
         $where_bit = "\nand ";
      }
   }
   $self->build_ord($sel_d,$uf_type);
   $self->and_finally($sel_d,$l_sel_str);
}
sub and_finally {
   my $self = shift;

   my($af_d,$cm) = @_;

   # Now we've built up our full SQL statement for this table,
   # fill a Perl array with everything and display it.

   $ary_ref = $self->{Database_conn}->selectall_arrayref($cm);

   $min_row = 0;
   $max_row = @$ary_ref;
   if ($max_row == 0){
      main::mes($af_d, $main::lg{no_rows});
   } else {
      $gc = $min_row;

      my $c_d = $af_d->DialogBox(-title=>$m_t);

      my(@lb) = qw/-anchor n -side top -expand 1 -fill both/;
      my $top_frame = $c_d->Frame->pack(@lb);
   
      my $t = $top_frame->Scrolled('Text',
                                   -height=>16,
                                   -wrap=>'none',
                                   -cursor=>undef,
                                   -foreground=>$main::fc,
                                   -background=>$main::bc);

      for my $i (0..$ind_bd_cnt) {
         $lrg_t[$i] = "";
         $w = $t->Entry(-textvariable=>\$i_ac[$i],
                        -cursor=>undef);
         $t->windowCreate('end',-window=>$w);
   
         $w = $t->Entry(-textvariable=>\$lrg_t[$i],
                        -cursor=>undef,
                        -foreground=>$main::fc,
                        -background=>$main::ec,
                        -width=>40);

         $t->windowCreate('end',-window=>$w);
         $t->insert('end', "\n");
      }
      $t->configure(-state=>'disabled');
      $t->pack(@lb);

      my $c_br = $c_d->Frame->pack(-before=>$top_frame,
                                   -side=>'bottom',
                                   -expand=>'no');
   
      $gen_sc = 
         $c_br->Scale( 
             -orient=>'horizontal',
             -label=>"$main::lg{rec_of} " . $max_row,
             -length=>400,
             -sliderrelief=>'raised',
             -from=>1,-to=>$max_row,
             -tickinterval=>($max_row/8),

             -command=>[ 
                sub {   $self->calc_scale_record($gen_sc->get())
                    }  ]

                     )->pack(side=>'left');

      $c_br->Button(-text=>$main::ssq,
                    -command=>sub{$self->see_sql($c_d,$l_sel_str)}

                   )->pack(side=>'right');

      $self->go_for_gold();
      $c_d->Show;
   }
   undef $ary_ref;
}
sub calc_scale_record {
   my $self = shift;

   # Whizz backwards and forwards through the records

   my($sv) = @_;
   $gc = $sv - 1;

   $self->go_for_gold();

}
sub go_for_gold {
   my $self = shift;

   # Work out which row of information to display,
   # and then display it.

   my $curr_ref = $ary_ref->[$gc];
   for my $i (0..$ind_bd_cnt) {
      $lrg_t[$i] = $curr_ref->[$i];
   }
   $gen_sc->set(($gc + 1));
}
sub build_ord {

   my $self = shift;

   # It all gets a bit nasty here.  This works out
   # the user's intentions on how to order their
   # required information.

   my($bl_d,$uf_type) = @_;
   my $l_chk = 0;

   my $i;

   for $i (0..$ind_bd_cnt){
      if ($i_uc[$i] == 1){
         $l_chk = 1;
      }
   }

   if ($l_chk == 1){

      $self->now_build_ord($bl_d,$uf_type);

      if ($uf_type eq 'index'){

         $self->really_build_index($bl_d,$own,$obj);

      } else {

         $l_sel_str = $l_sel_str . "\norder by ";
         for my $cl (1..$tot_i_cnt){
            $l_sel_str = $l_sel_str . "$tot_ind_ar[$ih[$cl]] ";
            if ($dsc_n[$ih[$cl]] == 1){
               $l_sel_str = $l_sel_str . "desc ";
            }
            if ($cl != $tot_i_cnt){
               $l_sel_str = $l_sel_str . ", ";
            }
         }
      }
   } else {
      if ($uf_type eq 'index'){
         main::mes($bl_d,$main::lg{no_cols_sel});
      }
   }
}
sub now_build_ord {
   my $self = shift;

   # This helps build up the ordering SQL string.

   my($nbo_d,$uf_type) = @_;
   $tot_i_cnt = 0;

   my $i;

   for $i (0..$ind_bd_cnt){
      if ($i_uc[$i] == 1){
         $tot_i_cnt++;
         $tot_ind_ar[$tot_i_cnt] = $i_ac[$i];
      }
   }
   my $b_d = $nbo_d->DialogBox(-title=>$m_t); 

   $b_d->Label(  -text=>$main::lg{ind_ord_arrng},
                 -anchor=>'n'
              )->pack(-side=>'top');

   my $t = $b_d->Scrolled('Text',
                          -height=>16,
                          -wrap=>'none',
                          -cursor=>undef,
                          -foreground=>$main::fc,
                          -background=>$main::bc);

   if ($uf_type eq 'index'){

      # User may be wanting to generate DDL to create new Index.
      # If so, this picks up the other information required.

      my $id_name = $main::lg{ind_name} . ':';

      $w = $t->Entry(-textvariable=>\$id_name,
                     -background=>$main::fc,
                     -foreground=>$main::ec);

      $t->windowCreate('end',-window=>$w);

      $ind_name = 'INDEX_NAME';
      $w = $t->Entry(-textvariable=>\$ind_name,
                     -cursor=>undef,
                     -foreground=>$main::fc,
                     -background=>$main::ec);
      $t->windowCreate('end',-window=>$w);
      $t->insert('end', "\n");

      my $tabp_name = $main::lg{tabsp} . ':';

      $w = $t->Entry(-textvariable=>\$tabp_name,
                     -background=>$main::fc,
                     -foreground=>$main::ec);

      $t->windowCreate('end',-window=>$w);

      $t_n = "TABSPACE_NAME";
      my $t_l = $t->BrowseEntry(-cursor=>undef,
                             -variable=>\$t_n,
                             -foreground=>$main::fc,
                             -background=>$main::ec);

      $t->windowCreate('end',-window=>$t_l);
      $t->insert('end', "\n");
   
      my $sth = 
         $self->{Database_conn}->prepare($self->f_str('now_build_ord','1'))||
                die $self->{Database_conn}->errstr; 
      $sth->execute;

      my $i = 0;
      my @tot_obj;

      my @res;

      while (@res = $sth->fetchrow) {
         $tot_obj[$i] = $res[0];
         $i++;
      }
      $sth->finish;

      my @h_ar = sort @tot_obj;
      foreach(@h_ar){
         $t_l->insert('end', $_);
      }
      $t->insert('end', "\n");
   }
   my @pos_txt;
   for $i (1..($tot_i_cnt + 2)){
      if ($i <= $tot_i_cnt){
         $pos_txt[$i] = "Pos $i";
         $w = $t->Entry(-textvariable=>\$pos_txt[$i],
                        -width=>7,
                        -background=>$main::fc,
                        -foreground=>$main::ec);
      } else {
         if ($i == ($tot_i_cnt + 1)){
            $pos_txt[$i] = $main::lg{i_col};
            $w = $t->Entry(-textvariable=>\$pos_txt[$i],
                           -background=>$main::fc,
                           -foreground=>$main::ec);
         } else {
            unless ($uf_type eq 'index'){
               $pos_txt[$i] = $main::lg{i_desc};
               $w = $t->Entry(-textvariable=>\$pos_txt[$i],
                              -width=>8,
                              -background=>$main::fc,
                              -foreground=>$main::ec);
            }
         }
      }
      $t->windowCreate('end',-window=>$w);
   }
   $t->insert('end', "\n");

   # The following is all a bit horrible.  I'm afraid 
   # you're going to have to work it out for yourself.
   # It's not nice, you may not want to bother.

   my $j_row;

   for $j_row (1..$tot_i_cnt){

      $ih[$j_row] = $j_row;
      $dsc_n[$j_row] = 0;
      $o_ih[$j_row] = $ih[$j_row];

      my $j_col;

      for $j_col (1..($tot_i_cnt + 2)){
         if ($j_col <= $tot_i_cnt){

            $w = $t->Radiobutton(
                        -relief=>'flat',
                        -value=>$j_row,
                        -variable=>\$ih[$j_col],
                        -width=>4,
                        -command=>[ sub {  $self->j_inri()  }]);

            $t->windowCreate('end',-window=>$w);
         } else {
            if ($j_col == ($tot_i_cnt + 1)){

               $w = $t->Entry( -textvariable=>\$tot_ind_ar[$j_row],
                               -cursor=>undef,
                               -foreground=>$main::fc,
                               -background=>$main::ec
                             );

               $t->windowCreate('end',-window=>$w);
            } else {
               unless ($uf_type eq 'index'){

                  $w = $t->Checkbutton( -variable=>\$dsc_n[$j_row],
                                        -relief=>'flat',
                                        -width=>6);

                  $t->windowCreate('end',-window=>$w);
               }
            }
         }
      }
      $t->insert('end', "\n");
   }
   $t->configure(-state=>'disabled');
   $t->pack();
   $b_d->Show;
}
sub really_build_index {
   my $self = shift;

   # Picks up everything finally reqd. to build
   # up the DDL for index creation

   my($rbi_d,$own,$obj) = @_;

   my $d = $rbi_d->DialogBox();

   $d->add( "Label",
            -text=>"$main::lg{ind_crt_for} $own.$obj"
          )->pack(side=>'top');

   my $l_text = $d->Scrolled( 'Text',
                              -wrap=>'none',
                              -cursor=>undef,
                              -foreground=>$main::fc,
                              -background=>$main::bc
                            );

   $l_text->pack(-expand=>1,-fil=>'both');

   tie (*L_TXT, 'Tk::Text', $l_text);

   my $cm = $self->f_str('build_ind','1');

   for my $cl (1..$tot_i_cnt){
      my $bs = " v_this_build($cl) := '$tot_ind_ar[$ih[$cl]]'; ";
      $cm = $cm . $bs;
   }

   my $cm_part2 = $self->f_str('build_ind','2');
   $cm = $cm . "\n" . $cm_part2;

   $self->{Database_conn}->func(1000000, 'dbms_output_enable');

   my $sth = $self->{Database_conn}->prepare( $cm ) || 
                die $self->{Database_conn}->errstr; 
   $sth->bind_param(1,$own);
   $sth->bind_param(2,$obj);
   $sth->bind_param(3,$tot_i_cnt);
   $sth->execute;

   my $full_list;
   $full_list = scalar $self->{Database_conn}->func('dbms_output_get');
   if (length($full_list) != 0){
      my $avg_entry_size = $full_list + 0.00;

      my($pct_free,$initrans) = $self->ind_prep($self->f_str('build_ind','3'),$own,$obj);
      my($n_rows) =             $self->ind_prep($self->f_str('build_ind','4') . ' ' . $own . '.' . $obj . ' ');
      my($avail_data_space) =   $self->ind_prep($self->f_str('build_ind','5'),$Block_Size,$initrans,$pct_free);
      my($space) = $self->ind_prep($self->f_str('build_ind','6'),$avail_data_space,$avg_entry_size,$avg_entry_size);
      my ($blocks_req) =         $self->ind_prep($self->f_str('build_ind','7'),$n_rows,$avg_entry_size,$space);
      my ($initial_extent) =     $self->ind_prep($self->f_str('build_ind','8'),$blocks_req,$Block_Size);
      my ($next_extent) =        $self->ind_prep($self->f_str('build_ind','9'),$initial_extent);

      print L_TXT "\nrem  Index Script for new index ${ind_name} on ${own}.${obj}\n\n";
      print L_TXT "create index ${own}.${ind_name} on\n";
      print L_TXT "   ${own}.${obj} (\n";
      for my $cl (1..$tot_i_cnt){
         my $bs = "      $tot_ind_ar[$ih[$cl]]\n";
         if ($cl != $tot_i_cnt){
            $bs = $bs . ', ';
         }
         print L_TXT $bs;
      }
      print L_TXT "   ) tablespace ${t_n}\n";
      print L_TXT "   storage (initial ${initial_extent}K next ${next_extent}K pctincrease 0)\n";
      print L_TXT "   pctfree ${pct_free};\n\n";
      print L_TXT "\nrem Average Index Entry Size:  ${avg_entry_size}   ";

      my $b = $l_text->Button(-text=>"Calculation SQL",-command=>sub{$self->see_sql($d,$cm)});
      $l_text->window('create','end',-window=>$b);

      print L_TXT "\nrem Database Block Size:       ${Block_Size}\n";
      print L_TXT "rem Current Table Row Count:   ${n_rows}\n";
      print L_TXT "rem Available Space Per Block: ${avail_data_space}\n";
      print L_TXT "rem Space For Each Index:      ${space}\n";
      print L_TXT "rem Blocks Required:           ${blocks_req}\n\n";
   }
   $d->Show;
}

sub ind_prep {

   my $self = shift;

   # Helper function for working out Index DDL

   my $cm = shift;
   my @bindees = @_;
   my $sth = $self->{Database_conn}->prepare($cm) || 
                die $self->{Database_conn}->errstr; 
   my $num_bindees = @bindees;
   if ($num_bindees > 0){
      my $i;
      for ($i = 1;$i <= $num_bindees;$i++){
         $sth->bind_param($i,$bindees[($i - 1)]);
      }
   }
   $sth->execute;
   my @res = $sth->fetchrow;
   $sth->finish;
   return @res;
}
sub j_inri {
   my $self = shift;

   # Here lies the end of sanity.  Welcome!

   my $i = 0;
   my $cl = 0;
   for $cl (1..$tot_i_cnt){
      if ($o_ih[$cl] != $ih[$cl]){
         $i = $cl;
         last;
      }
   }
   if ($i > 0){
      for $cl (1..$tot_i_cnt){
         unless ($cl == $i){
            if ($ih[$cl] == $ih[$i]){
                $ih[$cl] = $o_ih[$i];
                $o_ih[$cl] = $ih[$cl];
                last;
            }
         }
      }
      $o_ih[$i] = $ih[$i];
   }
}
sub tab_det_orac {
   my $self = shift;

   # Produces simple graphical representations of complex
   # percentage style reports.

   my ( $title, $func ) = @_;

   print STDERR "tab_det_orac: selfmw >" . 
      $self->{Main_window} . "<\n" if ($main::debug > 0);

   my $d = 
      $self->{Main_window}->DialogBox(
         -title=>"$title: $main::v_db ($main::lg{blk_siz} $Block_Size)"
                                     );

   my $cf = $d->Frame;
   $cf->pack(-expand=>'1',-fill=>'both');

   my $c = $cf->Scrolled( 'Canvas',
                          -relief=>'sunken',
                          -bd=>2,
                          -width=>500,
                          -height=>280,
                          -background=>$main::bc
                        );

   $keep_tablespace = 'XXXXXXXXXXXXXXXXX';

   my $cm = $self->f_str($func,'1');

   my $sth = $self->{Database_conn}->prepare( $cm ) || 
                die $self->{Database_conn}->errstr; 

   if($func eq 'tab_det_orac'){
      my $i;
      for ($i = 1;$i <= 6;$i++){
         $sth->bind_param($i,$Block_Size);
      }
   }
   $sth->execute;

   my $i = 1;

   my $Grand_Total = 0.00;
   my $Grand_Used_Mg = 0.00;
   my $Grand_Free_Mg = 0.00;

   my @res;

   my $Use_Pct;
   my $Used_Mg;
   my $Total;
   my $Fname;
   my $T_Space;
   my $Free_Mg;

   while (@res = $sth->fetchrow) {
     if($func eq 'tabspace_diag'){
        if($res[0] eq 'free'){
           $Free_Mg = $res[2];
           next;
        } else {
           $T_Space = $res[1];
           $Fname = '';
           $Total = $res[2];
           $Used_Mg = $Total - $Free_Mg;
           $Use_Pct = ($Used_Mg/$Total)*100;
        }
     } else {
        ($T_Space,$Fname,$Total,$Used_Mg,$Free_Mg,$Use_Pct) = @res;
     }
     if ((!defined($Used_Mg)) || (!defined($Use_Pct))){
        $Used_Mg = 0.00;
        $Use_Pct = 0.00;
     }
     $Grand_Total = $Grand_Total + $Total;
     $Grand_Used_Mg = $Grand_Used_Mg + $Used_Mg;
     if (defined($Free_Mg)){
        $Grand_Free_Mg = $Grand_Free_Mg + $Free_Mg;
     }
     if($func ne 'tab_det_orac'){
        $Fname = '';
     } 
     if($func eq 'tune_health'){
        $Use_Pct = $Total;
     }
     $self->add_item( $func,
                      $c,
                      $i,
                      $T_Space,
                      $Fname,
                      $Total,
                      $Used_Mg,
                      $Free_Mg,
                      $Use_Pct
                    );
     $i++;
   }
   $sth->finish;

   if($func ne 'tune_health'){
      my $Grand_Use_Pct = (($Grand_Used_Mg/$Grand_Total)*100.00);

      $self->add_item(  $func,
                        $c,
                        0,
                        '',
                        '',
                        $Grand_Total,
                        $Grand_Used_Mg,
                        $Grand_Free_Mg,
                        $Grand_Use_Pct
                     );
   }

   my $b = $c->Button( -text=>$main::ssq,
                       -command=>sub{  $self->see_sql( $d , $cm )  });

   print STDERR "tab_det_orac: i >$i<\n" if ($main::debug > 0);

   my $y_start = $self->work_out_why($i);

   $c->create(  'window', 
                '1c',
                "$y_start" . 'c',
                -window=>$b,
                -anchor=>'nw',
                -tags=>'item'
             );

   $c->configure(-scrollregion=>[ $c->bbox("all") ]);
   $c->pack(-expand=>'yes',-fill=>'both');
   $d->Show;

}

sub work_out_why {
   my $self = shift;

   print STDERR "work_out_why: i >$_[0]<\n" if ($main::debug > 0);

   return (0.8 + (1.2 * $_[0]));
}

sub add_item {

   my $self = shift;

   # Produces bar line on canvas for simple charts.

   my (  $func,
         $c,
         $i,
         $T_Space,
         $Fname,
         $Total,
         $Used_Mg,
         $Free_Mg,
         $Use_Pct) = @_;

   my $old_length;
   my $tab_str;

   unless($i == 0){
      if ($keep_tablespace eq $T_Space){
         $tab_str = sprintf("%${old_length}s ", '');
      } else {
         $old_length = length($T_Space);
         $tab_str = sprintf("%${old_length}s ", $T_Space);
      }
      $keep_tablespace = $T_Space;
   }
   my $thickness = 0.4;

   my $y_start = $self->work_out_why($i);

   my $y_end = $y_start + 0.4;
   my $chopper;
   if($func ne 'tune_health'){
      $chopper = 20.0;
   } else {
      $chopper = 10.0;
   }
   my $dst_f = ($Use_Pct/$chopper) + 0.4;

   print STDERR "add_item: c >$c<\n" if ($main::debug > 0);

   $c->create( ( 'rectangle', 
                 "$dst_f" . 'c',
                 "$y_start". 'c',
                 '0.4c',
                 "$y_end" . 'c'),

               -fill=>$main::hc

             );
  
   $y_start = $y_start - 0.4;

   my $this_text;

   if($i == 0){

      my $bit = '';

      $this_text = "$main::lg{db} " . 
                   sprintf("%5.2f", $Use_Pct) . 
                   '% '. 
                   $main::lg{full} . 
                   $bit;
   } else {

      $this_text = "$tab_str $Fname " . 
                   sprintf("%5.2f", $Use_Pct) . 
                   '%';

   }

   $c->create(   (   'text',
                     '0.4c',
                     "$y_start" . 'c',
                     -anchor=>'nw',
                     -justify=>'left',
                     -text=>$this_text  
                 )
             );

   $y_start = $y_start + 0.4;

   if($func ne 'tune_health'){

      $c->create( ( 'text',
                    '5.2c',
                    "$y_start" . 'c',
                    -anchor=>'nw',
                    -justify=>'left',
                    -text=>sprintf("%10.2fM Total %10.2fM Used %10.2fM Free",
                                   $Total, 
                                   $Used_Mg, 
                                   $Free_Mg
                                  )
                  )
                );
   }
}
sub dbwr_fileio {
   my $self = shift;

   # Works out File/IO and produces graphical report.

   my $t_tit = "$main::lg{file_io} $main::v_db";
   my $d = $self->{Main_window}->DialogBox(-title=>$t_tit);
   my $cf = $d->Frame;
   $cf->pack(-expand=>'1',-fill=>'both');

   my $c = $cf->Scrolled(  'Canvas',
                           -relief=>'sunken',
                           -bd=>2,
                           -width=>500,
                           -height=>280,
                           -background=>$main::bc
                        );

   my $cm = $self->f_str('dbwr_fileio','1');

   my $sth = $self->{Database_conn}->prepare( $cm ) || 
                die $self->{Database_conn}->errstr; 
   $sth->execute;
   my $max_value = 0;
   my $i = 0;
 
   my @res;
   my @dbwr_fi;

   while (@res = $sth->fetchrow) {
      $dbwr_fi[$i] = [ @res ];
      $i++;
      for $i (1 .. 6){
         if ($res[$i] > $max_value){
            $max_value = $res[$i];
         }
      }
   }
   $sth->finish;

   if($i > 0){

      $i--;

      for $i (0 .. $i){

         $self->dbwr_print_fileio(  $c, 
                                    $max_value, 
                                    $i,
                                    $dbwr_fi[$i][0],
                                    $dbwr_fi[$i][1],
                                    $dbwr_fi[$i][2],
                                    $dbwr_fi[$i][3],
                                    $dbwr_fi[$i][4],
                                    $dbwr_fi[$i][5],
                                    $dbwr_fi[$i][6]
                                 );
      }
   }

   my $b = $c->Button(-text=>$main::ssq,
                      -command=>sub{$self->see_sql($d,$cm)});

   my $y_start = $self->this_pak_get_y(($i + 1));

   $c->create(  'window', 
                '1c', 
                "$y_start" . 'c',
                -window=>$b,
                -anchor=>'nw',
                -tags=>'item'
             );

   $c->configure(-scrollregion=>[ $c->bbox("all") ]);

   $c->pack(-expand=>'yes',-fill=>'both');
   $d->Show;
}
sub this_pak_get_y {
   my $self = shift;
   return (($_[0] * 2.5) + 0.2);
}
sub dbwr_print_fileio {
   my $self = shift;

   # Prints out lines required for File/IO graphical report.

   my (  $c,
         $max_value,
         $y_start,
         $name,
         $phyrds,
         $phywrts,
         $phyblkrd,
         $phyblkwrt,
         $readtim,
         $writetim    ) = @_;

   my @stf = ('', $phyrds,$phywrts,$phyblkrd,$phyblkwrt,$readtim,$writetim);

   my $local_max = $stf[1];
   my $i;

   for $i (2 .. 6){
      if($stf[$i] > $local_max){
         $local_max = $stf[$i];
      }
   }
   my @txt_stf = (   '', 
                  'phyrds',
                  'phywrts',
                  'phyblkrd',
                  'phyblkwrt',
                  'readtim',
                  'writetim'
              );


   my $screen_ratio = 0.00;
   $screen_ratio = ($max_value/10.00);
   my $txt_name = 0.1;

   my $x_start = 2;
   $y_start = $self->this_pak_get_y($y_start);

   my $act_figure_pos = $x_start + ($local_max/$screen_ratio) + 0.5;
   my $txt_y_start;

   for $i (1 .. 6){
      my $x_stop = $x_start + ($stf[$i]/$screen_ratio);
      my $y_end = $y_start + 0.2;

      $c->create(   (  'rectangle',
                       "$x_start" . 'c',
                       "$y_start" . 'c',
                       "$x_stop" . 'c',
                       "$y_end" . 'c'
                    ),

                    -fill=>$main::hc

                );

      $txt_y_start = $y_start - 0.15;

      $c->create(   (   'text', 
                        "$txt_name" . 'c', 
                        "$txt_y_start" . 'c',
                        -anchor=>'nw',
                        -justify=>'left',
                        -text=>"$txt_stf[$i]"
                    )
                );


      $c->create(   (   'text', 
                        "$act_figure_pos" . 'c', 
                        "$txt_y_start" . 'c',
                        -anchor=>'nw',
                        -justify=>'left',
                        -text=>"$stf[$i]"
                    )
                );

      $y_start = $y_start + 0.3;
   }
   $txt_y_start = $y_start - 0.10;

   $c->create(   (   'text', 
                     "$x_start" . 'c', 
                     "$txt_y_start" . 'c',
                     -anchor=>'nw',
                     -justify=>'left',
                     -text=>"$name"
                 )
             );

}

sub errors_orac {
   my $self = shift;

   # Creates DBA Viewer window

   my $cm = $self->f_str('errors_orac','1');

   my $sth = $self->{Database_conn}->prepare( $cm ) || 
                die $self->{Database_conn}->errstr; 

   $sth->execute;
   my $detected = 0;

   my @res;

   while (@res = $sth->fetchrow) {
      $detected++;
      if($detected == 1){

         $main::swc{errors_orac} = MainWindow->new();
         $main::swc{errors_orac}->title($main::lg{err_obj});

         my(@err_lay) = qw/-side top -padx 5 -expand no -fill both/;

         my $err_menu = $main::swc{errors_orac}->Frame->pack(@err_lay);
         my $orac_li = $main::swc{errors_orac}->Photo(-file=>'img/orac.gif');

         $err_menu->Label(-image=>$orac_li,
                          -borderwidth=>2,
                          -relief=>'flat'
                         )->pack(-side=>'left',-anchor=>'w');

         $err_menu->Button(
            -text=>$main::lg{exit},
            -command=> 
               sub{  
                  $main::swc{errors_orac}->withdraw();
                  $main::sub_win_but_hand{errors_orac}->configure(
                                                             -state=>'active'
                                                                 )
                  }

                          )->pack(-side=>'left');

         my $err_top = $main::swc{errors_orac}->Frame->pack(-side=>'top',
                                                         -padx=>5,
                                                         -expand=>'yes',
                                                         -fill=>'both');

         $main::swc{errors_orac}->{text} = 
             $err_top->ScrlListbox(-width=>50,
                                   -background=>$main::bc,
                                   -foreground=>$main::fc
                                  )->pack(-side=>'top',
                                          -expand=>'yes',
                                          -fill=>'both');

         $err_top->Label(  -text=>$main::lg{doub_click},
                           -anchor=>'s',
                           -relief=>'groove'

                        )->pack(-side=>'bottom',
                                -before=>$main::swc{errors_orac}->{text},
                                -expand=>'no');

         main::iconize($main::swc{errors_orac});
      }
      $main::swc{errors_orac}->{text}->insert('end', @res);
   }
   $sth->finish;
   if($detected == 0){
      $self->{Main_window}->Busy;
      main::mes($self->{Main_window},$main::lg{no_rows_found});
      $self->{Main_window}->Unbusy;
   } else {

      $main::sub_win_but_hand{errors_orac}->configure(-state=>'disabled');
      $main::swc{errors_orac}->{text}->pack();

      $main::swc{errors_orac}->{text}->bind(
         '<Double-1>', 
         sub{  $main::swc{errors_orac}->Busy;
               $self->selected_error(
               $main::swc{errors_orac}->{text}->get('active')
                                     );
               $main::swc{errors_orac}->Unbusy}
                                       );
   }
}
sub dbas_orac {
   my $self = shift;

   # Creates DBA Viewer window

   my $cm = $self->f_str('dbas_orac','1');
   my $sth = $self->{Database_conn}->prepare( $cm ) || 
                die $self->{Database_conn}->errstr; 
   $sth->execute;
   my $detected = 0;

   my @res;

   while (@res = $sth->fetchrow) {
      $detected++;

      if($detected == 1){

         $main::swc{dbas_orac} = MainWindow->new();
         $main::swc{dbas_orac}->title($main::lg{dba_views});

         my(@dba_lay) = qw/-side top -padx 5 -expand no -fill both/;

         my $dba_menu = $main::swc{dbas_orac}->Frame->pack(@dba_lay);
         my $orac_li = $main::swc{dbas_orac}->Photo(-file=>'img/orac.gif');

         $dba_menu->Label(-image=>$orac_li,
                          -borderwidth=>2,
                          -relief=>'flat')->pack(-side=>'left',-anchor=>'w');

         $dba_menu->Button(
            -text=>$main::lg{exit},
            -command=>

               sub{
                  $main::swc{dbas_orac}->withdraw();
                  $main::sub_win_but_hand{dbas_orac}->configure(
                                                             -state=>'active'
                                                               )
                  } 

                          )->pack(-side=>'left');
      
         (@dba_lay) = qw/-side top -padx 5 -expand yes -fill both/;
         my $dba_top = $main::swc{dbas_orac}->Frame->pack(@dba_lay);

         $main::swc{dbas_orac}->{text} = 
            $dba_top->ScrlListbox(-width=>50,
                                  -background=>$main::bc,
                                  -foreground=>$main::fc
                                 )->pack(-expand=>'yes',-fill=>'both');

         $dba_top->Label(-text=>$main::lg{doub_click},
                         -anchor=>'s',
                         -relief=>'groove'
                        )->pack(-expand=>'no',
                                -side=>'bottom',
                                -before=>$main::swc{dbas_orac}->{text}
                               );

         main::iconize($main::swc{dbas_orac});
      }
      $main::swc{dbas_orac}->{text}->insert('end', @res);
   }
   $sth->finish;
   if($detected == 0){
      $self->{Main_window}->Busy;
      main::mes($self->{Main_window},$main::lg{no_rows_found});
      $self->{Main_window}->Unbusy;
   } else {

      $main::sub_win_but_hand{dbas_orac}->configure(-state=>'disabled');
      $main::swc{dbas_orac}->{text}->pack();

      $main::swc{dbas_orac}->{text}->bind(
         '<Double-1>',
         sub{ 
              print STDERR "dbas_orac: 0\n" if ($main::debug > 0);
              $main::swc{dbas_orac}->Busy;
              print STDERR "dbas_orac: 1\n" if ($main::debug > 0);
              $self->{Main_window}->Busy;
              print STDERR "dbas_orac: 2\n" if ($main::debug > 0);
              $self->univ_form( $self->{Main_window},
                                'SYS',
                                $main::swc{dbas_orac}->{text}->get('active'),
                                'form'
                              );
              print STDERR "dbas_orac: 3\n" if ($main::debug > 0);
              $self->{Main_window}->Unbusy;
              print STDERR "dbas_orac: 4\n" if ($main::debug > 0);
              $main::swc{dbas_orac}->Unbusy;
              print STDERR "dbas_orac: 5\n" if ($main::debug > 0);
            } 

                                   );
   }
}
sub addr_orac {

   print STDERR "in addr_orac:\n" if ($main::debug > 0);

   my $self = shift;

   # Creates DBA Viewer window

   my $cm = $self->f_str('addr_orac','1');
   my $sth = $self->{Database_conn}->prepare( $cm ) || 
                die $self->{Database_conn}->errstr; 
   $sth->execute;
   my $detected = 0;

   my @res;

   while (@res = $sth->fetchrow) {
      $detected++;
      if($detected == 1){
         $main::swc{addr_orac} = MainWindow->new();
         $main::swc{addr_orac}->title($main::lg{spec_addrss});

         my(@adr_lay) = qw/-side top -padx 5 -expand no -fill both/;
         my $addr_menu = $main::swc{addr_orac}->Frame->pack(@adr_lay);
         my $orac_li = $main::swc{addr_orac}->Photo(-file=>'img/orac.gif');


         $addr_menu->Label( -image=>$orac_li,
                            -borderwidth=>2,
                            -relief=>'flat'
                          )->pack(-side=>'left',
                                  -anchor=>'w');

         $addr_menu->Button(
            -text=>$main::lg{exit},
            -command=> 

               sub{ 
                  $main::swc{addr_orac}->withdraw();
                  $main::sub_win_but_hand{addr_orac}->configure(
                                                          -state=>'active'
                                                               )
                  } 

                           )->pack(-side=>'left');


         (@adr_lay) = qw/-side top -padx 5 -expand yes -fill both/;
         my $adr_top = $main::swc{addr_orac}->Frame->pack(@adr_lay);

         $main::swc{addr_orac}->{text} = 
            $adr_top->ScrlListbox(-width=>20,
                                  -background=>$main::bc,
                                  -foreground=>$main::fc
                                 )->pack(-expand=>'yes',-fill=>'both');

         $adr_top->Label(-text=>$main::lg{doub_click},
                         -anchor=>'s',
                         -relief=>'groove'

                        )->pack(   -expand=>'no',
                                   -side=>'bottom',
                                   -before=>$main::swc{addr_orac}->{text}
                               );

         main::iconize($main::swc{addr_orac});
      }
      $main::swc{addr_orac}->{text}->insert('end', @res);
   }
   $sth->finish;

   if($detected == 0){

      $self->{Main_window}->Busy;
      main::mes($self->{Main_window},$main::lg{no_rows_found});
      $self->{Main_window}->Unbusy;

   } else {

      $main::sub_win_but_hand{addr_orac}->configure(-state=>'disabled');
      $main::swc{addr_orac}->{text}->pack();

      $main::swc{addr_orac}->{text}->bind(
         '<Double-1>', 
         sub{  
               print STDERR "addr_orac: a1\n" if ($main::debug > 0);

               my $loc_addr = $main::swc{addr_orac}->{text}->get('active');

               print STDERR "addr_orac: a2\n" if ($main::debug > 0);

               $self->f_clr( $main::v_clr );
               my $cm = $self->f_str( 'sel_addr' , '1' );
               $self->show_sql( $cm , 
                                $main::lg{sel_addr} . ': ' . $loc_addr,
                                $loc_addr );

               print STDERR "addr_orac: a3\n" if ($main::debug > 0);

            }  
                                     );

   }
}

sub sids_orac {

   my $self = shift;

   # Creates DBA Viewer window

   my $cm = $self->f_str('sids_orac','1');
   my $sth = $self->{Database_conn}->prepare( $cm ) || 
                die $self->{Database_conn}->errstr; 
   $sth->execute;
   my $detected = 0;

   my @res;

   while (@res = $sth->fetchrow) {
      $detected++;
      if($detected == 1){
         $main::swc{sids_orac} = MainWindow->new();
         $main::swc{sids_orac}->title($main::lg{spec_sids});

         my(@sid_lay) = qw/-side top -padx 5 -expand no -fill both/;
         my $sid_menu = $main::swc{sids_orac}->Frame->pack(@sid_lay);
         my $orac_li = $main::swc{sids_orac}->Photo(-file=>'img/orac.gif');

         $sid_menu->Label(
                           -image=>$orac_li,
                           -borderwidth=>2,
                           -relief=>'flat'

                         )->pack( -side=>'left',
                                  -anchor=>'w' );

         $sid_menu->Button(  
            -text=>$main::lg{exit},
            -command=> 

               sub{ 
                  $main::swc{sids_orac}->withdraw();
                  $main::sub_win_but_hand{sids_orac}->configure(
                                                            -state=>'active'
                                                               ) 
                  } 

                          )->pack(-side=>'left');

         (@sid_lay) = qw/-side top -padx 5 -expand yes -fill both/;
         my $sid_top = $main::swc{sids_orac}->Frame->pack(@sid_lay);

         $main::swc{sids_orac}->{text} = 
            $sid_top->ScrlListbox(-width=>20,
                                  -background=>$main::bc,
                                  -foreground=>$main::fc
                                 )->pack(-expand=>'yes',-fill=>'both');

         $sid_top->Label(-text=>$main::lg{doub_click},
                         -anchor=>'s',
                         -relief=>'groove'

                        )->pack(  -expand=>'no',
                                  -side=>'bottom',
                                  -before=>$main::swc{sids_orac}->{text}
                               );

         main::iconize($main::swc{sids_orac});
      }
      $main::swc{sids_orac}->{text}->insert('end', @res);
   }
   $sth->finish;
   if($detected == 0){
      $self->{Main_window}->Busy;
      main::mes($self->{Main_window},$main::lg{no_rows_found});
      $self->{Main_window}->Unbusy;
   } else {

      $main::sub_win_but_hand{sids_orac}->configure(-state=>'disabled');
      $main::swc{sids_orac}->{text}->pack();

      $main::swc{sids_orac}->{text}->bind(
         '<Double-1>', 
         sub { $main::swc{sids_orac}->Busy;

               $self->f_clr( $main::v_clr );
               my $cm = $self->f_str( 'sel_sid' , '1' );
               my $sid_param = $main::swc{sids_orac}->{text}->get('active');
               $self->show_sql( $cm , 
                                $main::lg{sel_sid} . ': ' . $sid_param,
                                $sid_param );

               $main::swc{sids_orac}->Unbusy}
                                     );
   }
}
sub gh_roll_name {
   my $self = shift;

   my $cm = $self->f_str('time','2');
   my $sth = $self->{Database_conn}->prepare($cm) || 
                die $self->{Database_conn}->errstr; 
   $sth->execute;
   my($sample_time) = $sth->fetchrow;

   $sth->finish;

   $self->{Text_var}->insert('end', "$sample_time\n");

   $self->show_sql( $self->f_str('roll_orac','2'),
                    $main::lg{roll_seg_stats}
                  );

   $self->about_orac('txt/Oracle/rollback.1.txt');

}
sub gh_roll_stats {
   my $self = shift;

   my $cm = $self->f_str('time','2');
   my $sth = $self->{Database_conn}->prepare($cm) || 
                die $self->{Database_conn}->errstr; 
   $sth->execute;
   my($sample_time) = $sth->fetchrow;
   $sth->finish;

   $self->{Text_var}->insert('end', "$sample_time\n");
   $self->show_sql( $self->f_str('roll_orac','1'),
                    $main::lg{roll_seg_stats}
                  );
   $self->about_orac('txt/Oracle/rollback.2.txt');
}

sub gh_pool_frag {

   my $self = shift;

   $self->about_orac('txt/Oracle/pool_frag.1.txt');
   $self->show_sql( $self->f_str('pool_frag','1'),
                    $main::lg{pool_frag}
                  );
   $self->about_orac('txt/Oracle/pool_frag.2.txt');

}

sub explain_plan {

   my $self = shift;

   # First of all, check if we have the correct PLAN_TABLE
   # on board?

   my $explain_ok = 0;

   if ($self->check_exp_plan() == 0){

      main::mes($self->{Main_window},$main::lg{use_utlxplan});

   } else {

      $explain_ok = 1;

   }

   $main::swc{explain_plan} = MainWindow->new();
   $main::swc{explain_plan}->title($main::lg{explain_plan});

   my(@exp_lay) = qw/-side top -padx 5 -expand no -fill both/;
   my $dmb = $main::swc{explain_plan}->Frame->pack(@exp_lay);

   my $orac_li = $main::swc{explain_plan}->Photo(-file=>'img/orac.gif');

   $dmb->Label( -image=>$orac_li,
                -borderwidth=>2,
                -relief=>'flat'
             )->pack( -side=>'left',
                      -anchor=>'w' );

   # Add buttons.  Add a holder for the actual explain plan
   # button so we can enable/disable it later

   if($explain_ok){
      $expl_butt = $dmb->Button(-text=>$main::lg{explain},
                                -command=>sub{ $self->explain_it() }
                               )->pack(side=>'left');

      $dmb->Button(  -text=>$main::lg{clear},
                     -command=>sub{
                         $main::swc{explain_plan}->Busy;
                         $w_explain[2]->delete('1.0','end');
                         $w_holders[0] = $main::v_sys;
                         $w_holders[1] = $main::lg{explain_help};
                         $expl_butt->configure(-state=>'normal');
                         $main::swc{explain_plan}->Unbusy;
                                                  }
                  )->pack(side=>'left');
   }

   $dmb->Button(
      -text=>$main::lg{exit},

      -command=> sub{

         $main::swc{explain_plan}->withdraw();
         $main::sub_win_but_hand{explain_plan}->configure(-state=>'active');
         undef $sql_browse_arr

                    } 

               )->pack(-side=>'left');

   # Set counter up

   my $i;

   # Produce input/update screen.  First, get the SQL select
   # array filled, so we can work out the field titles

   my $cm = $self->f_str('explain_plan','2');
   my $sth;
   $sql_browse_arr = $self->do_query_fetch_all( $cm, \$sth );
   @w_titles = @{$sth->{NAME}};

   # Work out the length of the Titles fields

   my $num_cols = @w_titles;

   my $l_label_width = 5;
   my $l_entry_width = 55;
   my $l_entry_height = 13;

   for($i=0;$i<$num_cols;$i++){
      if( (length($w_titles[$i])) > $l_label_width){
         $l_label_width = length($w_titles[$i]);
      }
   }

   # Now work out screen sizings

   (@exp_lay) = qw/-side top -padx 5 -expand yes -fill both/;
   my $top_slice = $main::swc{explain_plan}->Frame->pack(@exp_lay);

   $main::swc{explain_plan}->{text} = 
      $top_slice->Scrolled(  'Text',
                             -wrap=>'none',
                             -cursor=>undef,
                             -height=>($l_entry_height + $num_cols + 3),
                             -width=>($l_entry_width + $l_label_width + 5),
                             -foreground=>$main::fc,
                             -background=>$main::bc
                          );

  
   for($i=0;$i<$num_cols;$i++){

      #  0  user
      #  1  address
      #  2  SQL

      $w_holders[$i] = '';
      $w_explain[$i] = $main::swc{explain_plan}->{text}->Entry( 
                              -textvariable=>\$w_titles[$i],
                              -cursor=>undef,
                              -width=>$l_label_width
                                                  );
      $main::swc{explain_plan}->{text}->windowCreate('end',
                                                     -align=>'top',
                                                     -window=>$w_explain[$i]);

      if ($i == 2){
         $w_explain[$i] = 
            $main::swc{explain_plan}->{text}->Scrolled( 
                                        'Text',
                                        # -wrap=>'none', # NB: commented out
                                        -cursor=>undef,
                                        -height=>$l_entry_height,
                                        -width=>$l_entry_width,
                                        -foreground=>$main::fc,
                                        -background=>$main::ec
                                                      );
      }
      else {
         $w_explain[$i] = 
              $main::swc{explain_plan}->{text}->Entry( 
                                 -textvariable=>\$w_holders[$i],
                                 -cursor=>undef,
                                 -width=>$l_entry_width
                                                      );
      }
      $w_explain[$i]->configure(-background=>$main::ec,
                                -foreground=>$main::fc);

      $main::swc{explain_plan}->{text}->windowCreate('end',
                                                     -window=>$w_explain[$i]);
      $main::swc{explain_plan}->{text}->insert('end', "\n");
   }
   $main::swc{explain_plan}->{text}->pack( -expand=>1,
                                           -fil=>'both');

   # Stop anyone getting rid of text-embedded
   # widgets with a dodgy delete key press

   $main::swc{explain_plan}->{text}->configure( -state=>'disabled' );

   # Now build up the slider, which will trawl through v$sqlarea to
   # paste up various bits of SQL text currently in database.

   print STDERR "explain_plan: w_titles >@w_titles<\n" if ($main::debug > 0);

   my $sql_min_row = 0;
   my $sql_max_row = @$sql_browse_arr;

   unless ($sql_max_row == 0){
      $sql_row_count = $sql_min_row;

      # Build up scale slider button, and splatt onto window.

      my $bot_slice = 
             $main::swc{explain_plan}->Frame->pack( -before=>$top_slice,
                                                    -side=>'bottom',
                                                    -padx=>5,
                                                    -expand=>'no',
                                                    -fill=>'both'
                                                  );

      $sql_slider = 
         $bot_slice->Scale( 
            -orient=>'horizontal',
            -label=>"$main::lg{rec_of} " . $sql_max_row,
            -length=>400,
            -sliderrelief=>'raised',
            -from=>1,
            -to=>$sql_max_row,
            -tickinterval=>($sql_max_row/8),
            -command=>[ sub {$self->calc_scale_sql($sql_slider->get(),
                                                   $explain_ok)} ]
                          )->pack(side=>'left');

      $bot_slice->Button(
         -text=>$main::ssq,
         -command=>sub { $self->see_sql( $main::swc{explain_plan}, $cm )}

                        )->pack(side=>'right');

      $self->pick_up_sql($explain_ok);

   } else {
      # There are no rows (very unlikely) so blatt out memory
      undef $sql_browse_arr;
   }

   $main::sub_win_but_hand{explain_plan}->configure(-state=>'disabled');
   main::iconize($main::swc{explain_plan});

   return;
}
sub explain_it {
   my $self = shift;

   # Takes the SQL statement directly from the screen
   # and tries an 'Explain Plan' on it.  I'm leaving the
   # SQL hard-coded here so you can see EXACTLY what's
   # going on, particularly as we're dipping our toes
   # into DML.

   # BTW We're automatically set up for autocommit, with  
   # DBI, so there's no need to commit the 'delete'
   # transaction

   my $sql_bit = $w_explain[2]->get("1.0", "end");

   # The following is the first (and hopefully only)
   # DML in the whole of Orac.

   my $ex_sql = ' explain plan set statement_id ' .
                '= \'orac_explain_plan\' for ' . $sql_bit . ' ';

   my $del_sql = ' delete from plan_table ' .
                 'where statement_id = \'orac_explain_plan\' ';

   my $rc  = $self->{Database_conn}->do( $del_sql );
   $rc  = $self->{Database_conn}->do( $ex_sql );

   my $cm =   ' select rtrim(lpad(\'  \',2*level)|| ' . "\n" .
              ' rtrim(operation)||\' \'|| ' . "\n" .
              ' rtrim(options)||\' \'|| ' . "\n" .
              ' object_name) query_plan ' . "\n" .
              ' from plan_table ' . "\n" .
              ' where statement_id = \'orac_explain_plan\' ' . "\n" .
              ' connect by prior id = parent_id ' .
              ' and statement_id = \'orac_explain_plan\' ' . "\n" .
              ' start with id = 0 and statement_id = \'orac_explain_plan\' ';

   my $sth = $self->{Database_conn}->prepare( $cm ) || 
                die $self->{Database_conn}->errstr; 
   $sth->execute;

   # Clear screen where required.
   $self->f_clr($main::v_clr);

   my @res;
   while (@res = $sth->fetchrow) {
      $self->{Text_var}->insert('end', "$res[0]\n");
   }
   $sth->finish;

   $self->see_plsql( $cm );

}
sub calc_scale_sql {
   my $self = shift;

   # Whizz backwards and forwards through the 
   # v$sqlarea records

   my($sv,$expl_ok) = @_;
   $sql_row_count = $sv - 1;

   $self->pick_up_sql($expl_ok);

}
sub pick_up_sql {
   my $self = shift;

   my($expln_ok) = @_;

   # Work out which row of information to display,
   # and then display it.

   my $curr_ref = $sql_browse_arr->[$sql_row_count];

   # Now chop it up for formatting purposes.

   # Put up the name in the holding variable
   my $i;
   for ($i=0;$i<3;$i++)
   {
      if($i == 2){
         $w_explain[$i]->delete('1.0','end');
         $w_explain[$i]->insert('1.0',$curr_ref->[$i]);
      }
      else {
         $w_holders[$i] = $curr_ref->[$i];
      }
   }
   $sql_slider->set(($sql_row_count + 1));

   # Enable the 'Explain Plan' button, if the logged on
   # user, is the same as the SQL's user

   if($expln_ok){
      if($main::v_sys eq $w_holders[0]){
         $expl_butt->configure(-state => 'normal');
      } else {
         $expl_butt->configure(-state => 'disabled');
      }
   }
   return;
}
sub check_exp_plan {
   my $self = shift;

   # Check if the currently logged on DBA user
   # has a valid PLAN_TABLE table to put
   # 'Explain Plan' results to insert into.

   my $cm = $self->f_str('explain_plan','1');
   my $sth = $self->{Database_conn}->prepare($cm) || 
                die $self->{Database_conn}->errstr; 
   $sth->execute;
   my $detected = 0;

   my @res;

   while (@res = $sth->fetchrow) {
      $detected = $res[0];
   }
   $sth->finish;

   return $detected;
}

sub block_size {
   my $self = shift;
   return $Block_Size;
}

sub who_hold
{
   my $self = shift;

   # Slightly complicated.
   # Build up a scrolling list of all the users
   # who're holding everyone back.  This can be
   # double-clicked to bring up a 'See SQL' type
   # screen.  After scroll-list, insert the report.

   my $scrllist_str;

   my $l_osuser;
   my $l_username;
   my $l_serial;
   my $l_sid;
   my $l_pid;

   my $l_wait_title;
   my $l_hold_title;
   my $l_os_title;
   my $l_ser_title;
   my $l_sid_title;
   my $l_pid_title;

   my @res;
   my @title_values;

   my $cm = $self->f_str( 'wait_hold' , '1' );

   # Now show Report for finding Who's holding whom?
   # Make sure the screen isn't cleared beforehand.


   my $scroll_box;
   my $scroll_label;

   my $sth = $self->{Database_conn}->prepare( $cm ) || 
                die $self->{Database_conn}->errstr; 
   $sth->execute;

   my $l_counter = 0;

   while ( @res = $sth->fetchrow ) {

      if ($l_counter == 0){
         my $i;
         for ($i = 0;$i < $sth->{NUM_OF_FIELDS};$i++){
            $title_values[$i] = $sth->{NAME}->[$i];
         }
         $l_wait_title = $title_values[0];
         $l_os_title = $title_values[7];
         $l_hold_title = $title_values[6];
         $l_ser_title = $title_values[8];
         $l_sid_title = $title_values[9];
         $l_pid_title = $title_values[10];

         $l_counter = 1;

         $scroll_label = 
            $self->{Text_var}->Label( 
               -text=>"$main::lg{see_sql} $main::lg{doub_click}",
               -relief=>'raised'
                                    );

         $scroll_box =
            $self->{Text_var}->ScrlListbox(-width=>76,
                                           -height=>3,
                                           -background=>$main::ec,
                                           -foreground=>$main::fc
                                          );

         print STDERR "who_hold: scroll_box>$scroll_box<\n" 
            if ($main::debug > 0);

         $self->{Text_var}->windowCreate('end',-window=>$scroll_label);
         $self->{Text_var}->insert('end', "\n");

         $self->{Text_var}->windowCreate('end',-window=>$scroll_box);
         $self->{Text_var}->insert('end', "\n");
      } 

      # Wait User first 

      $l_username = $res[0];
      $l_osuser = $res[1];
      $l_serial = $res[2];
      $l_sid = $res[3];
      $l_pid = $res[4];

      $scrllist_str = "$l_wait_title:$l_username," .
                      "$l_os_title:$l_osuser," .
                      "$l_ser_title:$l_serial," .
                      "$l_sid_title:$l_sid," .
                      "$l_pid_title:$l_pid";

      print STDERR "who_hold: (wait) scrllist_str>$scrllist_str<\n" 
         if ($main::debug > 0);

      $scroll_box->insert('end', $scrllist_str);

      # Hold User

      $l_username = $res[6];
      $l_osuser = $res[7];
      $l_serial = $res[8];
      $l_sid = $res[9];
      $l_pid = $res[10];

      print STDERR "who_hold: l_pid       >$l_pid<\n" 
         if ($main::debug > 0);

      print STDERR "who_hold: l_pid_title >$l_pid_title<\n" 
         if ($main::debug > 0);

      $scrllist_str = "$l_hold_title:$l_username," .
                      "$l_os_title:$l_osuser," .
                      "$l_ser_title:$l_serial," .
                      "$l_sid_title:$l_sid," .
                      "$l_pid_title:$l_pid";

      print STDERR "who_hold: scrllist_str>$scrllist_str<\n" 
         if ($main::debug > 0);

      $scroll_box->insert('end', $scrllist_str);
   }
   $sth->finish;

   if ($l_counter == 1){
      $scroll_box->bind(
   
            '<Double-1>', 
            sub{  $self->{Main_window}->Busy;
                  my @first_string = split(',', $scroll_box->get('active') );
   
                  print STDERR "who_hold: first_string>@first_string<\n" 
                     if ($main::debug > 0);
   
                  my @v_osuser = split('\:', $first_string[1]);
                  my @v_username = split('\:', $first_string[0]);
                  my @v_sid = split('\:', $first_string[2]);
   
                  print STDERR "who_hold: v_osuser  >$v_osuser[1]<\n" 
                     if ($main::debug > 0);
                  print STDERR "who_hold: v_username>$v_username[1]<\n" 
                     if ($main::debug > 0);
                  print STDERR "who_hold: v_sid     >$v_sid[1]<\n" 
                     if ($main::debug > 0);
   
                  $self->who_what( 1,
                                   $v_osuser[1],
                                   $v_username[1],
                                   $v_sid[1]
                                 );
                  $self->{Main_window}->Unbusy
               }
                       );
      $self->{Text_var}->insert('end', "\n");
   }

   # And finally, thank goodness, the actual report.

   $self->show_sql( $cm , $main::lg{who_hold} );
}

sub mts_mem
{
   my $self = shift;

   # Report for finding MTS statistics,
   # and providing secondary button to reveal further stats

   my $cm = $self->f_str( 'sess_curr_max_mem' , '1' );

   my $l_counter = 0;

   my $who_what_str;

   my $l_stat;
   my $l_stat_title;

   my $scroll_label;
   my $scroll_box;

   my @res;
   my @title_values;

   my $sth = $self->{Database_conn}->prepare( $cm ) || 
                die $self->{Database_conn}->errstr; 
   $sth->execute;

   while ( @res = $sth->fetchrow ) {

      if ($l_counter == 0){
         my $i;
         for ($i = 0;$i < $sth->{NUM_OF_FIELDS};$i++){
            $title_values[$i] = $sth->{NAME}->[$i];
         }
         $l_stat_title = $title_values[0];

         $l_counter = 1;

         $scroll_label = 
            $self->{Text_var}->Label( 
               -text=>"$main::lg{doub_click}",
               -relief=>'raised'
                                    );

         $scroll_box =
            $self->{Text_var}->ScrlListbox(-width=>40,
                                           -height=>3,
                                           -background=>$main::ec,
                                           -foreground=>$main::fc
                                          );

         print STDERR "mts_mem: scroll_box>$scroll_box<\n" 
            if ($main::debug > 0);

         $self->{Text_var}->windowCreate('end',-window=>$scroll_label);
         $self->{Text_var}->insert('end', "\n");

         $self->{Text_var}->windowCreate('end',-window=>$scroll_box);
         $self->{Text_var}->insert('end', "\n");
      } 

      $l_stat = $res[0];

      $who_what_str = "${l_stat_title}:$l_stat";
      $scroll_box->insert('end', $who_what_str);
   }
   $sth->finish;

   if ($l_counter == 1){
      $scroll_box->bind(
   
            '<Double-1>', 
            sub{  $self->{Main_window}->Busy;
                  my @stat_str = split('\:', $scroll_box->get('active') );
   
                  print STDERR "mts_mem: stat_str>@stat_str<\n" 
                     if ($main::debug > 0);
   
                  $self->who_what( 2,
                                   $stat_str[1]
                                 );
                  $self->{Main_window}->Unbusy
               }
                       );
   
      $self->{Text_var}->insert('end', "\n");
   }
   $self->show_sql( $cm , $main::lg{mts_mem} );
   
}

sub do_a_generic {

   my $self = shift;

   # On the final level of an HList, does the actual work
   # required.

   my ($l_mw, $l_gen_sep, $l_hlst, $input) = @_;

   print STDERR "do_a_generic: l_mw      >$l_mw<\n" if ($main::debug > 0);
   print STDERR "do_a_generic: l_gen_sep >$l_gen_sep<\n" if ($main::debug > 0);
   print STDERR "do_a_generic: l_hlst    >$l_hlst<\n" if ($main::debug > 0);
   print STDERR "do_a_generic: input     >$input<\n" if ($main::debug > 0);

   $l_mw->Busy;
   my $owner;
   my $generic;
   my $dum;

   ($owner, $generic, $dum) = split("\\$l_gen_sep", $input);
   
   my $cm = $self->f_str( $l_hlst , '99' );

   $self->{Database_conn}->func(1000000, 'dbms_output_enable');
   my $second_sth = $self->{Database_conn}->prepare( $cm ) || die $self->{Database_conn}->errstr; 
   
   $second_sth->bind_param(1,$owner);
   $second_sth->bind_param(2,$generic);
   $second_sth->execute;

   my $d = $l_mw->DialogBox();

   $d->add("Label",
           -text=>"$l_hlst $main::lg{sql_for} $owner.$generic"
          )->pack(side=>'top');

   my $l_txt = $d->Scrolled('Text',
                         -height=>16,
                         -wrap=>'none',
                         -cursor=>undef,
                         -foreground=>$main::fc,
                         -background=>$main::bc
                        )->pack(-expand=>1,-fil=>'both');

   tie (*L_TEXT, 'Tk::Text', $l_txt);

   my $j = 0;
   my $full_list;

   while($j < 10000){
      $full_list = scalar $self->{Database_conn}->func('dbms_output_get');
      if(!defined($full_list)){
         last;
      }
      if((length($full_list)) == 0){
         last;
      }
      print L_TEXT "$full_list\n";
      $j++;
   }
   print L_TEXT "\n\n  ";

   my @b;
   $b[0] = $l_txt->Button( -text=>$main::ssq,
                           -command=>sub{$self->see_sql($d,$cm)}
                         );

   $l_txt->window('create', 'end',-window=>$b[0]);

   if ( ($l_hlst eq 'Tables') || ($l_hlst eq 'Indexes') ){
      print L_TEXT "\n\n  ";

      my $i = 1;
      my @tablist;

      if ($l_hlst eq 'Tables') {

         @tablist = ('Tab_FreeSpace', 
                     'Tab_Indexes',
                     'Table_Constraints',
                     'Triggers',
                     'Comments');
      }
      elsif ($l_hlst eq 'Indexes') {

         @tablist = ('Index_FreeSpace');
      }

      foreach ( @tablist ) {

         my $this_txt = $_;

         $b[$i] = 
            $l_txt->Button(
               -text=>"$this_txt",
               -command=>sub { $self->do_a_generic($d, '.', $this_txt, $input);
                             },
                          );

         $l_txt->window('create', 'end',-window=>$b[$i]);
         print L_TEXT " ";
         $i++;
      }
      print L_TEXT "\n\n  ";

      if ($l_hlst eq 'Tables') {
         $b[$i] = 
            $l_txt->Button(-text=>$main::lg{form},
                           -command=>
                              sub{$d->Busy;
   
      print STDERR "\ndo_a_gen form: d    >$d<\n" if ($main::debug > 0);
      print STDERR "do_a_gen form: owner  >$owner<\n" if ($main::debug > 0);
      print STDERR "do_a_gen form: generic>$generic<\n\n" if ($main::debug > 0);
  
                                  $self->univ_form($d,
                                                   $owner,
                                                   $generic,
                                                   'form');
                                  $d->Unbusy }
                          );

         $l_txt->window('create', 'end',-window=>$b[$i]);
         $i++;
         print L_TEXT " ";

         $b[$i] = 
            $l_txt->Button(
               -text=>$main::lg{build_index},
               -command=> sub{$d->Busy;
   
      print STDERR "\ndo_a_gen inx: d       >$d<\n" if ($main::debug > 0);
      print STDERR "do_a_gen inx: owner   >$owner<\n" if ($main::debug > 0);
      print STDERR "do_a_gen inx: generic >$generic<\n\n" if ($main::debug > 0);
   
                              $self->univ_form($d,$owner,$generic,'index');
                              $d->Unbusy }
                          );
   
         $l_txt->window('create','end',-window=>$b[$i]);
      }
   } elsif ($l_hlst eq $main::lg{views}){
      print L_TEXT "\n\n  ";

      $b[1] = 
         $l_txt->Button(
            -text=>$main::lg{form},
            -command=>sub{  $d->Busy;

   print STDERR "do_a_gen vform: d       >$d<\n" if ($main::debug > 0);
   print STDERR "do_a_gen vform: owner   >$owner<\n" if ($main::debug > 0);
   print STDERR "do_a_gen vform: generic >$generic<\n" if ($main::debug > 0);

                            $self->univ_form(  $d,
                                               $owner,
                                               $generic,
                                               'form'
                                            );
                            $d->Unbusy }
                       );

      $l_txt->window('create', 'end',-window=>$b[1]);
   }
   print L_TEXT "\n\n";
   $d->Show;
   $l_mw->Unbusy;
}
1;
