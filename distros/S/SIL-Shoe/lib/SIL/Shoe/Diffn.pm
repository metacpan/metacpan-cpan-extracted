package SIL::Shoe::Diffn;

use Algorithm::Diff qw(sdiff);
use SIL::Shoe::Data;
use Algorithm::Merge qw(merge);
use Digest::MD5;

$VERSION = "0.02";  #   MJPH    10-JUN-2004     Original

sub shmerge
{
    my ($opts, $origfile, @files) = @_;
    my ($sh, %keylist, @output, @jobs, @objs, @keys, $i, $j, $k);
    my ($res);

    # prepare indexes and assemble a list of all keys
    $osh = prepare_db($origfile, \%keylist, \@keys);
    foreach $sh (@files)
    { push(@objs, prepare_db($sh, \%keylist, \@keys)); }

    foreach $k (@keys)
    {
        my (@maps);
        print STDERR "." if ($opts->{'-debug'});
        # not in the original, then add new records for each one found elsewhere
        if (!defined $osh->{' index'}{$k})
        {
            for ($i = 0; $i < @objs; $i++)
            { 
                for ($j = 0; $j < scalar @{$objs[$i]{' index'}{$k}}; $j++)
                { push (@jobs, [$k, undef, (undef) x $i, 
                    [$objs[$i]{' index'}{$k}[$j], $objs[$i]{' md5index'}{$k}[$j]]]); }
            }
        }
        else
        {
            # build mappings from original to new versions. All non-mapped new records add jobs
            for ($i = 0; $i < @objs; $i++)
            {
                # slow only if there is more than one original or more than one new
                if (@{$osh->{' index'}{$k}} > 1 || @{$objs[$i]{' index'}{$k}} > 1)
                {
                    my ($max) = max(scalar @{$osh->{' index'}{$k}}, scalar @{$objs[$i]{' index'}{$k}});
                    @map = multi_records($osh, $objs[$i], $osh->{' index'}{$k}, $objs[$i]{' index'}{$k},
                            $osh->{' md5index'}{$k}, $objs[$i]{' md5index'}{$k});
                
                    for ($j = 0; $j < $max; $j++)
                    { 
                        if (defined $map[$j])
                        { $maps[$map[$j]][$i] = $j; }
                        else        # new record, add a job
                        { push (@jobs, [$k, undef, (undef) x $i, 
                            [$objs[$i]{' index'}{$k}[$j], $objs[$i]{' md5index'}{$k}[$j]]]); }
                    }
                }
                else        # the mapping is easy
                { $maps[0][$i] = 0; }
            }
            # add aligned job entries for all originals
            for ($i = 0; $i < @maps; $i++)
            {
                my (@job) = ($k, [$osh->{' index'}{$k}[$i], $osh->{' md5index'}{$k}[$i]]);
                my ($found) = 1;
                
                for ($j = 0; $j <= $#{$maps[$i]}; $j++)
                {
                    if (defined $maps[$i][$j])
                    { push (@job, [$objs[$j]{' index'}{$k}[$maps[$i][$j]], $objs[$j]{' md5index'}{$k}[$maps[$i][$j]]]); }
                    else
                    { 
                        push (@job, undef);
                        $found = 0;
                    }
                }
                push (@jobs, [@job]) if ($found);
            }
        }
    }
    
    $res = sprintf("\\_sh %-5.5s %-4.4s %s\n\n", $osh->{' Version'}, $osh->{' CSum'}, $osh->{' Type'});
    
    foreach $k (@jobs)
    {
        print STDERR "+" if ($opts->{'-debug'});
        if (defined $k->[1])
        {
            my (@md5s, $diffi);
            my ($found, $diff) = (0, 0);
            
            for ($i = 0; $i < @objs; $i++)
            {
                next unless (defined $k->[$i + 2]);
                $found++;
                if ($k->[$i + 2][1] ne $k->[1][1])
                {
                    $diff++;
                    $diffi = $i;
                }
            }
            
            if ($found == @objs && !$diff)
            { $res .= output_record($osh, $k->[1][0]); }
            elsif ($diff == 1)
            { $res .= output_record($objs[$diffi], $k->[2 + $diffi][0]); }
            elsif ($diff > 1)
            {
                my (@merged);
                my (@f, @od);
                
                $osh->readrecord(\@f, $k->[1][0]);
                @od = make_difflist($osh, @f);
                
                for ($i = 0; $i < @objs; $i++)
                {
                    my (@fd);
                    next if ($k->[$i + 2][1] eq $k->[1][1]);
                    $objs[$i]->readrecord(\@f, $k->[2 + $i][0]);
                    @fd = make_difflist($objs[$i], @f);
                    if (@merged)
                    { 
                        @merged = merge(\@od, \@merged, \@fd, 
                            { CONFLICT => sub {fields_conflict(@_, %opts)}}, \&field_gen);
                    }
                    else
                    { @merged = (@fd); }
                }
                $res .= output_fields(@merged);
            }
                    
        }
        else
        {
            for ($i = 0; $i < @objs; $i++)
            { $res .= output_record($objs[$i], $k->[2 + $i][0]) if (defined $k->[2 + $i]); }
        }
        
        if ($opts->{'-outfh'})
        {
            $opts->{'-outfh'}->print($res);
            $res = '';
        }
    }
    return $res;
}

sub fields_conflict
{
    my ($lf, $rf, %opts) = @_;
    my (@diff, $d, @res);
    my ($cmarker) = $opts{'-cmarker'} || '__cm';
    
    @diff = sdiff($lf, $rf, sub {$_[0]->[0]});
    foreach $d (@diff)
    {
        if ($d->[0] eq '+')
        { push (@res, $d->[2]); }
        elsif ($d->[0] eq '-')
        { push (@res, $d->[1]); }
        elsif ($d->[1][0] eq $d->[2][0])
        { 
            push (@res, [$cmarker, '', "Conflicting $d->[1][0] fields"], $d->[1], $d->[2]);
            ${$opts{'-ccountref'}}++ if (defined $opts{'-ccountref'});
        }
        else
        { push (@res, $d->[1], $d->[2]); }
    }
    @res;
}

sub output_record
{
    my ($sh, $loc) = @_;
    my ($res);

    $sh->proc_record(sub {$res .= "$_[0]\n"}, $loc);
    $res .= "\n" unless ($res =~ m/\n\n$/os);
    return $res;
}

sub output_fields
{
    my (@diffs) = @_;
    my ($d, $res );
    
    foreach $d (@diffs)
    { $res .= "\\$d->[0] $d->[2]\n"; }
    $res .= "\n";
    return $res;
}

sub prepare_db
{
    my ($fname, $keylist, $keys) = @_;
    my ($k, $curri, $t);
    my ($sh) = SIL::Shoe::Data->new($fname) || die "Can't open $fname";
    my (@keyt) = map {[$_]} @{$keys};
    unshift (@keyt, []);
    
    $sh->index({'-md5' => 1});
    foreach $k (sort {$sh->{' index'}{$a}[0] <=> $sh->{' index'}{$b}[0]} keys %{$sh->{' index'}})
    { 
        if (defined $keylist->{$k})
        { $curri = $keylist->{$k}; }
        else
        {
            if ($curri == 0 && $#keyt > 1)
            { $curri++ while ($k gt $keyt[$curri + 1][0]); }     # this should be 'proper' sorting
            push (@{$keyt[$curri]}, $k); 
        }
    }
    %{$keylist} = ();
    @{$keys} = ();
    $curri = 1;
    foreach $t (@keyt)
    {
        foreach $k (@{$t})
        {
            next if (defined $keylist->{$k});
            $keylist->{$k} = $curri++;
            push (@{$keys}, $k);
        }
    }
    return $sh;
}
    
sub make_difflist
{
    my ($sh, @f) = @_;
    my (@res, $f);
    
    foreach $f (@f)
    {
        $f =~ m/^(\S+)\s*(\d*)$/o;
        push (@res, [$1, $2, $sh->{$f}]);
    }
    @res
}

sub field_gen
{ "\\$_[0]->[0] $_[0]->[2]"; }

# results in a map from new to base $map[$new] = $base
sub multi_records
{
    my ($bsh, $nsh, $base, $new, $bmd5, $nmd5) = @_;
    my (@costs, $i, $j, @nf, @bf, @nlist, @blist, @diff);

    return undef unless (defined $new);
    
    for ($i = 0; $i < @{$new}; $i++)
    {
        $nsh->readrecord(\@nf, $new->[$i]);
        @nlist = make_difflist($nsh, @nf);
        for ($j = 0; $j < @{$base}; $j++)
        {
            if ($nmd5->[$i] eq $bmd5->[$j])
            {
                $costs[$i][$j] = 0;
                next;
            }
            $cost = 0;
            $bsh->readrecord(\@bf, $base->[$j]);
            @blist = make_difflist($bsh, @bf);
            @diff = sdiff(\@blist, \@nlist, \&field_gen);
            foreach $d (@diff)
            {
                if ($d->[0] eq '+' || $d->[0] eq '-')
                { $cost += 1; }
                if ($d->[0] eq 'c')
                {
                    if ($d->[1][0] eq $d->[2][0])
                    { $cost += 1; }
                    else
                    { $cost += 2; }
                }
            }
            $costs[$i][$j] = $cost;
        }
    }
    cost_mapping(@costs);
}
    

sub cost_mapping
{
    my (@costs) = @_;
    my ($i, $j, $k, @res, $cost, @all_tries);
    
    for ($i = 0; $i < scalar @{$costs[0]}; $i++)
    {
        my (@order) = sort {$costs[$a][$i] <=> $costs[$b][$i]} (0 .. scalar @costs - 1);
        my (@trier, @triec, $tcost);
        
        foreach $j (@order)
        {
            for ($k = 0; $k < scalar @{$costs[$j]}; $k++)
            {
                $idx = (sort {$costs[$j][$a] <=> $costs[$j][$b]} (0 .. scalar @{$costs[$j]} - 1))[$k];
                $cost = $costs[$j][$idx];
                if (!defined $triec[$idx])
                {
                    $trier[$j] = $idx;
                    $triec[$idx] = $j;
                    $tcost += $cost;
                    last;
                }
            }
        }
        push (@all_tries, [$tcost, [@trier]]);
    }
    
    $best = (sort {$a->[0] <=> $b->[0]} @all_tries)[0];
    @res = @{$best->[1]};
    return @res;
}

sub max
{ $_[0] > $_[1] ? $_[0] : $_[1]; }

1;
