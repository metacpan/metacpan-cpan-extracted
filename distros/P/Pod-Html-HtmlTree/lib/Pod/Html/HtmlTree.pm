package Pod::Html::HtmlTree;

use strict;
use Pod::Html;
use File::Find;
use File::Path;
use File::Basename;
use List::Util qw/first/;
use Data::Dumper;
our $VERSION = 0.92;

sub new {
    my $class = shift;
    my $self  = shift || {};
    
    # default setting.
    $self->{pod_exts}  =  [ 'pm' ,'pl' ,'cgi','pod' ];
    $self->{mask_dir}  =  0775;
    $self->{mask_html} =  0664;

    bless $self , $class;
    return $self;
}

sub create {
    my $self = shift;

    my $paths_ref = $self->_get_paths();
    my $umask = umask 0000;   

    for my $file_ref ( @{ $paths_ref } ) {
        if ( !-d dirname( $file_ref->{outfile} ) ) {
            mkpath( dirname( $file_ref->{outfile} ) , 0 , $self->{mask_dir} ) ;
        }
         $self->{args} =  $self->{args} || [];
        my @args = @{ $self->{args} } ;
        push ( @args , '--infile='  . $file_ref->{infile}  );
        push ( @args , '--outfile=' . $file_ref->{outfile} );
   
        pod2html( @args );
        chmod $self->{mask_html} , $file_ref->{outfile} ;
    }
    unlink './pod2htmd.tmp';
    unlink './pod2htmi.tmp';

    umask $umask;
    return $paths_ref;
}

sub args {
    my $self = shift;
    my $arg  = shift;

    $self->{args} = [];
    
    foreach my $key ( keys %{ $arg } ) {
        my $value = $arg->{$key} eq '0' ? "--$key" :  "--$key=$arg->{$key}" ;
        push @{ $self->{args} } , $value ;
    }
}

#{{{ setter
sub pod_exts {
    my $self          = shift;
    $self->{pod_exts} = shift;
}
sub mask_dir {
    my $self          = shift;
    $self->{mask_dir} = shift;
}

sub mask_html {
    my $self           = shift;
    $self->{mask_html} = shift;
}

sub indir {
    my $self       = shift;
    $self->{indir} = shift;
}

sub outdir {
    my $self        = shift;
    $self->{outdir} = shift;
}

#}}}

#{{{ PRIVATE
sub _get_paths {
    my $self = shift;
    my @infiles = ();
    my @paths   = ();
    File::Find::find(
        sub {
            my $file_name = $_;
            if (!-d $_ && $self->_is_ok_ext( $file_name ) ) {
                push @infiles , $File::Find::name ;
            }
        },
        $self->{indir}
    );

    # set { outfile , infile } in array 
    for my $infile ( @infiles ) {
        # get ext
        my @splited_file_by_dot = split /\./ ,  $infile  ;
        my $ext                 = $splited_file_by_dot[-1];

        # get outfile 
        my $outfile = $infile;
        my $os = fileparse_set_fstype();
        if( $os eq 'MSWin32' || $os eq 'DOS' ) {
            my $indir   = $self->{indir};
            my $outdir  = $self->{outdir};
            $outfile    =~ s/\\/\//g;
            $indir      =~ s/\\/\//g;
            $outdir     =~ s/\\/\//g;
            $outfile    =~ s/$indir/$outdir/;
            $outfile    =~ s/\.$ext/\.html/;
            $outfile    =~ s/\//\\/g;
        }
        else {
            $outfile    =~ s/$self->{indir}/$self->{outdir}/;
            $outfile    =~ s/\.$ext/\.html/;
        }
        
        # make file hash
        my $file_ref = { 
            infile => $infile , 
            outfile => $outfile , 
        };
        push @paths , $file_ref ;
    };
    
    return \@paths;
}

sub _is_ok_ext {
    my $self      = shift;
    my $file_name = shift; 
    
    my $find = first { $file_name =~ /\.$_$/} @{ $self->{pod_exts} };
    return $find ? 1 : 0 ;
}
#}}}
1;


__END__

=head1 NAME

Pod::Html::HtmlTree - class to convert pod files to html tree

=head1 SYNOPSIS

 use Pod::Html::HtmlTree;
 use Data::Dumper;

 my $p = Pod::Html::HtmlTree->new;
 $p->indir    ( '/usr/lib/perl5/site_perl/5.8.3/Pod' );
 $p->outdir   ( '/tmp/pod'      );    
 $p->mask_dir ( 0777 );    # default is 0775
 $p->mask_html( 0777 ); # default is 0664
 $p->pod_exts ( [ 'pm' , 'pod' ] ); # default is [pm,pod,cgi,pl]
 # * you can use all arguments same as Pod::Html has except infile and outfile.
 # * use * 0 * for argument value which does not require to have value.
 $p->args({
    css =>'http://localhost/pod.css',
    index => 0,
 });

 my $files = $p->create;
 print Dumper ( $files ); 

=head1 DESCRIPTION

This module does same as Pod::Html module but make html tree.
Read L<Pod::Html> document for more detail.

You may want to look at  L<Pod::ProjectDocs> before using this module which may be more fun to you. 

=head1 AUTHOR

Tomohiro Teranishi C<tomohiro.teranishi@gmail.com>

=head1 SEE ALSO

L<Pod::Html>

=head1 COPYRIGHT

This program is distributed under the Artistic License

=cut
