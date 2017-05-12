package SIL::Shoe::Diff3;

use Algorithm::Diff qw(sdiff);
use SIL::Shoe::Data;
use Algorithm::Merge qw(merge);
use Digest::MD5;

sub shmerge
{
    my ($class, $oldf, $leftf, $rightf, %opts) = @_;
    my ($osh, $lsh, $rsh, %keylist, @output, @jobs);
    my ($res);

    $osh = prepare_db($oldf, \%keylist);
    $lsh = prepare_db($leftf, \%keylist);
    $rsh = prepare_db($rightf, \%keylist);

    foreach $k (sort {(defined $osh->{' index'}{$a} ? $osh->{' index'}{$a}[0] : 0xFFFFFFFF)
                    <=> (defined $osh->{' index'}{$b} ? $osh->{' index'}{$b}[0] : 0xFFFFFFFF)}
                    keys %keylist)
    {
        if (!defined $osh->{' index'}{$k})
        {
            if (defined $rsh->{' index'}{$k})
            { push (@jobs, map {[$k, undef, undef, $_]} @{$rsh->{' index'}{$k}}); }
            if (defined $lsh->{' index'}{$k})
            { push (@jobs, map {[$k, undef, $_, undef]} @{$lsh->{' index'}{$k}}); }
        }
        elsif (!defined $rsh->{' index'}{$k} && !defined $lsh->{' index'}{$k})
        { }     # deleted items
        elsif (@{$osh->{' index'}{$k}} > 1 || @{$rsh->{' index'}{$k}} > 1 || @{$lsh->{' index'}{$k}} > 1)
        {
            @lmap = multi_records($osh, $lsh, $osh->{' index'}{$k}, $lsh->{' index'}{$k});
            @rmap = multi_records($osh, $rsh, $osh->{' index'}{$k}, $rsh->{' index'}{$k});
            for ($m = 0; $m < @rmap; $m++)
            { @revmap[$rmap[$m]] = $m if (defined $rmap[$m]); }
            for ($m = 0; $m < @lmap; $m++)
            {
                push (@jobs, [$k, defined $lmap[$m] ? $osh->{' index'}{$k}[$lmap[$m]] : undef, 
                                $lsh->{' index'}{$k}[$m],
                                defined $lmap[$m] && defined $revmap[$lmap[$m]] ? 
                                $rsh->{' index'}{$k}[$revmap[$lmap[$m]]] : undef]);
            }
            for ($m = 0; $m < @{$rsh->{' index'}{$k}}; $m++)
            {
                push (@jobs, [$k, defined $rmap[$m] ? $osh->{' index'}{$k}[$rmap[$m]] : undef, 
                            undef, $rsh->{' index'}{$k}[$m]])
                    if (!defined $rmap[$m]);
            }
        }
        else
        { push (@jobs, [$k, $osh->{' index'}{$k}[0], $lsh->{' index'}{$k}[0], $rsh->{' index'}{$k}[0]]); }
    }
    
    $res = sprintf("\\_sh %-5.5s %-4.4s %s\n\n", $osh->{' Version'}, $osh->{' CSum'}, $osh->{' Type'});
    
    foreach $k (@jobs)
    {
        if (defined $k->[1])
        {
            if (!defined $k->[2])
            { 
                $md5 = Digest::MD5->new;
                $osh->proc_record(sub {$md5->add($_[0])}, $k->[1]);
                $omd5 = $md5->digest;
                
                $md5 = Digest::MD5->new;
                $rsh->proc_record(sub {$md5->add($_[0])}, $k->[3]);
                $rmd5 = $md5->digest;
                $res .= output_record($rsh, $k->[3]) if ($omd5 ne $rmd5);
            }
            elsif (!defined $k->[3])
            { 
                $md5 = Digest::MD5->new;
                $osh->proc_record(sub {$md5->add($_[0])}, $k->[1]);
                $omd5 = $md5->digest;
                
                $md5 = Digest::MD5->new;
                $lsh->proc_record(sub {$md5->add($_[0])}, $k->[2]);
                $lmd5 = $md5->digest;
                $res .= output_record($lsh, $k->[2]) if ($omd5 ne $lmd5);
            }
            else                                # all 3 records there, which are the same?
            {
                $md5 = Digest::MD5->new;
                $osh->proc_record(sub {$md5->add($_[0])}, $k->[1]);
                $omd5 = $md5->digest;
                
                $md5 = Digest::MD5->new;
                $lsh->proc_record(sub {$md5->add($_[0])}, $k->[2]);
                $lmd5 = $md5->digest;
                
                $md5 = Digest::MD5->new;
                $rsh->proc_record(sub {$md5->add($_[0])}, $k->[3]);
                $rmd5 = $md5->digest;
                
                if ($omd5 eq $lmd5)
                { $res .= output_record($rsh, $k->[3]); }
                elsif ($omd5 eq $rmd5)
                { $res .= output_record($lsh, $k->[2]); }
                else                            # all records there and different => clash
                {
                    my (@of, @lf, @rf, @od, @ld, @rd, @merged);
                    
                    $osh->readrecord(\@of, $k->[1]);
                    $lsh->readrecord(\@lf, $k->[2]);
                    $rsh->readrecord(\@rf, $k->[3]);
                    
                    @od = make_difflist($osh, @of);
                    @ld = make_difflist($lsh, @lf);
                    @rd = make_difflist($rsh, @rf);
                
                    @merged = merge(\@od, \@ld, \@rd, { CONFLICT => sub {fields_conflict(@_, %opts)}}, \&field_gen);
                    $res .= output_fields(@merged);
                }
            }
        }
        elsif (defined $k->[2])
        { $res .= output_record($lsh, $k->[2]); }
        else
        { $res .= output_record($rsh, $k->[3]); }
        if ($opts{'-outfh'})
        {
            $opts{'-outfh'}->print($res);
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
    my ($fname, $keylist) = @_;
    my ($sh) = SIL::Shoe::Data->new($fname) || die "Can't open $fname";
    
    $sh->index();
    foreach $k (keys %{$sh->{' index'}})
    { $keylist->{$k}++; }
    $sh;
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
    my ($bsh, $nsh, $base, $new) = @_;
    my (@costs, $i, $j, @nf, @bf, @nlist, @blist, @diff);
    
    for ($i = 0; $i < @{$new}; $i++)
    {
        $nsh->readrecord(\@nf, $new->[$i]);
        @nlist = make_difflist($nsh, @nf);
        for ($j = 0; $j < @{$base}; $j++)
        {
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

1;
