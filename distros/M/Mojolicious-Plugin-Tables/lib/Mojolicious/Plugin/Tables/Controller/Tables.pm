package Mojolicious::Plugin::Tables::Controller::Tables;

use Mojo::Base 'Mojolicious::Controller';

# 'shipped' is a special stash slot for passing serialisable things to json or templates.
# Other stash slots can be complex objects for use by templates.

sub ok {
    my $c       = shift;
    my $log     = $c->app->log;
    my $user_id = $c->stash('user_id') || die 'no user_id in stash';
    if ($c->allowed($user_id, 'tables')) {
        my $logourl = $c->app->config('logourl') || $c->url_for('/img/tables.png');
        my $model   = $c->app->config('model');
        $c->shipped( tablist => $model->{tablist},
                     bytable => $model->{bytable},
                     logourl => $logourl );
        $c->stash( schema=>$model->{schema} );
        return 1;
    }
    my $error = "tables activity unauthorised";
    $c->fail($error) if (($c->stash('format')||'x') eq 'json');
    $c->add_flash(errors=>$error);
    $c->redirect_to('/');
    return;
}

# more fine-grained permission control..
sub allowed { 1 }

sub page {
    my $c = shift;
    $c->shipped(start_with=>$c->param('start_with')) if $c->param('start_with')
}

sub table_ok {
    my $c      = shift;
    my $table  = $c->stash('table');
    my $schema = $c->stash('schema');
    my $bytable= $c->shipped('bytable');
    my $tinfo  = $bytable->{$table} || die "no table $table";
    my $source = $tinfo->{source};
    my $rs     = $schema->resultset($source) || die "no source $source";
    $c->stash(rs=>$rs);
    $c->shipped(table=>$table, tinfo=>$tinfo);
    1;
}

sub id_ok {
    my $c  = shift;
    my $id = $c->stash('id');
    my $rs = $c->stash('rs');
    my @ids = split(/-\|-/, $id); # as made by see Row::compound_ids
    if (my $row = $rs->find(@ids)) {
        $c->stash(row => $row);
        $c->shipped(id => $id);
        return 1;
    }
    my $table = $c->stash('table');
    die "no entry [$id] for table [$table]\n";
}

sub table {
    my $c      = shift;
    my $log    = $c->app->log;
    my $table  = $c->stash('table');
    my $rs     = $c->stash('rs');
    my $tinfo  = $c->shipped('tinfo');

    if (($c->stash('format')||'html') eq 'html') {
        $c->redirect_to("/tables?start_with=$table");
        return;
    }

    my $columns  = $tinfo->{columns};
    my $bycolumn = $tinfo->{bycolumn};
    my $has_a    = $tinfo->{has_a};
    my @has_a    = map { $_->{parent} } values %$has_a;

    my @order_bys;
    for (my $i=0; 1; $i++) {
        my $col = $c->param("order[$i][column]") // last;
        my $dir = $c->param("order[$i][dir]"   ) // last;
        push @order_bys, {col=>$col, dir=>$dir};
    }
    my $draw     = $c->param('draw')    || 0;
    my $start    = $c->param('start')   || 0;
    my $length   = $c->param('length')  || -1;
    my $search_v = $c->param('search[value]');
    my $search_r = $c->param('search[regex]');

    # q1: count all candiates
    my $recordsTotal    = $rs->count;
    my $recordsFiltered = $recordsTotal;
    
    my $attrs = {};
    my $where = [];

    # q2: count filtered candidates
    if ($search_v) {
        my $like_v = { ilike => "%$search_v%" };
        for my $col (@$columns) {
            my $info = $bycolumn->{$col};
            next if $info->{fkey};
            next unless $info->{data_type} eq 'varchar';
            push @$where, {$col=>$like_v};
        }
        $recordsFiltered = $rs->search($where, $attrs)->count;
    }

    # q3: full
    $attrs->{order_by} = [ map { {"-$_->{dir}" => $columns->[$_->{col}] } } @order_bys ]
                         if @order_bys;
    $attrs->{offset}   = $start;
    $attrs->{rows}     = $length if $length>0;
    #$log->debug("where " . $c->dumper($where));
    #$log->debug("attrs " . $c->dumper($columns));
    #$log->debug("odbys " . $c->dumper(\@order_bys));
    #$log->debug("attrs " . $c->dumper($attrs));
    my @rows = $rs->search($where, $attrs);

    my @data = map {
                    my $row = $_;
                    my $datum = {DT_RowId=>$row->compound_ids};
                    for (@$columns) {
                        my $info = $bycolumn->{$_};
                        if ($info->{fkey}) {
                            $datum->{$_} = undef;
                            if (my $frow = $row->$_) {
                                $datum->{$_} = sprintf('<a href="#">%s</a>',$frow)
                            }
                            next;
                        }
                        $datum->{$_} = $row->present($_, $info);
                    }
                    $datum
                } @rows;

    my $bundle = {
        draw            => $draw,
        recordsTotal    => $recordsTotal,
        recordsFiltered => $recordsFiltered,
        data            => \@data,
    };

    if (($c->stash('format')||'data') eq 'json') {
        $c->render( json => $bundle );
        return;
    }
    $c->render(data => $c->dumper($bundle));
}

sub edit {}
sub view {}
sub add { shift->render(template=>'tables/edit', dml_mode=>'add', row=>undef) }
sub del {
    my $c = shift;
    $c->add_stash(messages => "Confirm.. all you see here will be removed");
    $c->render(template=>'tables/view', dml_mode=>'del');
}

sub nuke {
    my $c    = shift;
    my $table= $c->stash('table');
    my $row  = $c->stash('row');
    my $id   = $c->shipped('id');
    my $row0 = "$row";
    my $hits = $row->nuke;
    $c->add_flash(messages=>"REMOVED $row0 at key $id and all subordinate info.. $hits records in total") if $hits;
    my $url  = $c->url_for('/tables')->query(start_with=>$table);
    $c->redirect_to($url);

}

sub save {
    my $c      = shift;
    my $table  = $c->stash('table');
    my $rs     = $c->stash('rs');
    my $row    = $c->stash('row');
    my $schema = $c->stash('schema');
    my $id     = $c->shipped('id');
    my $tinfo  = $c->shipped('tinfo');
    my $bytable= $c->shipped('bytable');

    my $columns  = $tinfo->{columns};
    my $bycolumn = $tinfo->{bycolumn};

    if ($row) { # update
        for my $col (@$columns) {
            my $info = $bycolumn->{$col};
            if (defined (my $val = $c->param($col))) {
                $val = undef if $val eq '' && $info->{is_nullable};
                $row->$col($val);
            } elsif ($c->param("${col}_pre_checkbox")) {
                my $val = $info->{is_nullable}? undef: 'f';
                $row->$col($val);
            }
        }
        $row->update;
        $c->add_flash(messages=>"updated: $row");

    } else { # insert
        $row = $rs->new_result({});
        for my $col (@$columns) {
            my $info = $bycolumn->{$col};
            if (defined (my $val = $c->param($col))) {
                next if $val eq '' && $info->{is_nullable};
                $row->$col($val);
            }
        }
        if (eval { $row->insert }) {
            $row->discard_changes;
            $id = $row->id;
            $c->add_flash(messages=>"inserted at key $id: $row");
        } else {
            my $err = $@;
            $c->app->log->error("inserting a $table: $err");
            $c->add_stash(errors => "Database rejected the new record: $err");
            # if came from an add-child..
            if (my $psource   = $c->param('psource') and
                my $child     = $c->param('child')   and
                my $parent_id = $c->param('parent_id')) {
                my $prs       = $schema->resultset($psource);
                my $prow      = $prs->find($parent_id);
                my $ptable    = $prow->table;
                my $pinfo     = $bytable->{$ptable};
                $c->shipped(id=>$parent_id, table=>$ptable, tinfo=>$pinfo);
                $c->render(template=>'tables/view', row=>$prow, child=>$child);
            # else a stand-alone add.
            } else {
                $c->render(template=>'tables/edit', dml_mode=>'add', row=>undef);
            }
            return;
        }
    }
    my $redirect_to = $c->param('redirect_to') || "/tables/$table/$id/view";
    $c->redirect_to($redirect_to);
}

sub children {
    my $c        = shift;
    my $tinfo    = $c->shipped('tinfo');
    my $has_many = $tinfo->{has_many};
    my $children = $c->stash('children');
    my $row      = $c->stash('row');
    my $offset   = $c->param('offset') || 0;
    my $limit    = $c->param('limit') || 10;
    die "$children: unknown has-many collection" unless $has_many->{$children};
    my $cpkey    = $has_many->{$children}->{cpkey};
    my $dir      = 'asc';
    my $attrs    = {};
    if ($offset > 0) {
        $attrs->{offset} = $offset;
    } elsif ($offset == -1) { # get last page
        $dir = 'desc';
    } elsif ($offset == -2) { # get all.. in fact, apply safety valve of 1000
        $limit = 1000;
    }
    $attrs->{order_by} = {"-$dir"=>$cpkey};
    $attrs->{rows}     = $limit if $limit;
    #$c->app->log->debug("invoke child group $children with " . $c->dumper($attrs));
    my @rows = map { +{id=>$_->id, label=>"$_"} } $row->$children({}, $attrs);
    @rows = reverse @rows if $dir eq 'desc';
    if (($c->stash('format')||'html') eq 'json') {
        $c->render( json => \@rows );
        return;
    }
    $c->render(data => $c->dumper(\@rows));
}

sub navigate {
    my $c     = shift;
    my $log   = $c->app->log;
    my $to    = $c->param('to') || 'next';
    my $table = $c->stash('table');
    my $rs    = $c->stash('rs');
    my $row   = $c->stash('row');
    my $tinfo = $c->shipped('tinfo');
    my $id    = $c->shipped('id');
    my $pkeys = $tinfo->{pkeys};
    die "cannot navigate to $to" unless $to =~ /start|end|next|prev/;
    die "not supported for multi-barrel pkeys" if @$pkeys > 1;
    my $pkey   = $pkeys->[0];
    my $attrs  = { rows=>1, select=>[$pkey] };
    my $rhs;
    for ($to) {
        if (/next/ ) { $attrs->{order_by} = {-asc =>$pkey }; $rhs = {'>'=>$id}; last }
        if (/prev/ ) { $attrs->{order_by} = {-desc=>$pkey }; $rhs = {'<'=>$id}; last }
        if (/start/) { $attrs->{order_by} = {-asc =>$pkey }; last }
        if (/end/  ) { $attrs->{order_by} = {-desc=>$pkey }; last }
    }
    my $newid = $id;
    my $where = {};
    $where->{$pkey} = $rhs if $rhs;
    if (my $hit = $rs->search($where, $attrs)->first) {
        $newid = $hit->id;
    }
    $c->redirect_to("/tables/$table/$newid/view");
}

1;

