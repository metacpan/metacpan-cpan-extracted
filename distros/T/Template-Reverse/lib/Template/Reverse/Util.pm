package Template::Reverse::Util;

# ABSTRACT: Utils

require Exporter;
our @ISA='Exporter';
our @EXPORT = qw(partition partition_by);
our $VERSION = '0.202'; # VERSION

# port from Clojure
sub partition{
    my($len, $step, @list) = @_;
    my @ret;
    for(my $i=0; $i<@list-$len+1; $i+=$step){
        my @sublist = @list[$i..$i+$len-1];
        push(@ret, \@sublist);
    }
    return @ret;
}

# port from Clojure
sub partition_by{
    my($funcref, @list) = @_;
    my @ret;
    my $curarr;
    foreach my $item (@list){
        if( $funcref->($item) ){
            if($curarr){
                push(@ret, $curarr);
            }
            push(@ret, [$item]);   
            $curarr = [];
        }
        else{
            push(@{$curarr}, $item);
        }
    }
    push(@ret, $curarr) if @{$curarr} > 0;
    return @ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Reverse::Util - Utils

=head1 VERSION

version 0.202

=head1 AUTHOR

HyeonSeung Kim <sng2nara@hanmail.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by HyeonSeung Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
