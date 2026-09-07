# ABSTRACT: download novel /bbs thread
package Novel::Robot;
use strict;
use warnings;
use utf8;

use Novel::Robot::Parser;
use Novel::Robot::Packer;
use Novel::Robot::Browser;
use Encode::Locale;
use Encode;
use Term::ProgressBar;

our $VERSION = 0.48;

sub new {
	my ( $self, %opt ) = @_;
	$opt{max_process_num} ||= 3;
	$opt{type}            ||= 'html';
	$opt{class}            ||= 'novel';
	#$opt{agent}            ||= 'default';

	my $parser  = Novel::Robot::Parser->new( %opt );
	my $browser = Novel::Robot::Browser->new( %opt );
	my $packer  = Novel::Robot::Packer->new( %opt );

	bless { %opt, parser => $parser, packer => $packer, browser => $browser },
	__PACKAGE__;
}

sub set_parser {
	my ( $self, $site ) = @_;
	$self->{site}   = $self->{parser}->detect_site( $site );
	$self->{parser} = Novel::Robot::Parser->new( %$self );
	return $self;
}

sub set_packer {
	my ( $self, $type ) = @_;
	$self->{type}   = $type;
	$self->{packer} = Novel::Robot::Packer->new( %$self );
	return $self;
}

sub get_novel_info {
	my ( $self,  $url )       = @_;
	my ( $i_url, $post_data ) = $self->{parser}->generate_novel_url( $url );
	my $c = $self->{browser}->request_url( $i_url, $post_data );

	my $r = $self->{parser}->parse_novel(\$c);
	$r->{url} = $i_url;

	$r->{item_list} = $self->{parser}->parse_item_list( \$c);
	( $r->{item_list}, $r->{item_num} ) = $self->{parser}->update_item_list( $r->{item_list}, $url );

	return $r;
}

sub get_novel {
	my ( $self, $index_url, %o ) = @_;


	#class: novel, tiezi, page
	my $class = $self->{class} || 'novel';  
	my  $novel_ref = $self->can("get_${class}_ref")->( $self, $index_url, %o );
	return unless ( $novel_ref );

	my $item_list = $novel_ref->{item_list};
	return unless ( ref($item_list) eq 'ARRAY' and @$item_list );

	while ( @$item_list and ! $item_list->[-1]{content} ) {
		pop @$item_list;
	}

	return unless ( @$item_list );

	my $last_item_num = $novel_ref->{item_list}[-1]{id} ||  $novel_ref->{item_num} || scalar( @{ $novel_ref->{item_list} } ) ;

	my $dst_f = $self->{packer}->main( $novel_ref, \%o );
	my $dst_fname = decode(locale=>$dst_f);
	print encode(locale=>"info: $novel_ref->{writer}-$novel_ref->{book}-$last_item_num\noutput: $dst_fname\nlast_item_num: $last_item_num\n") if ( $o{verbose} );

	return wantarray ? ( $dst_f, $novel_ref ) : $dst_f;
} ## end sub get_novel

sub get_novel_ref {
	my ( $self, $index_url, %o ) = @_;

	#return $self->get_tiezi_ref( $index_url, %o ) if ( $self->{parser}->class() eq 'tiezi' );

	my ( $r, $item_list, $max_item_num );

	if ( $index_url !~ /^https?:/ ) { 
		#parse txt
		$r = $self->{parser}->parse_novel( $index_url, %o );
	} else {


		$r = $self->get_novel_items(
			$index_url,
			url_sub  => $self->{parser}->can( "generate_novel_url" ),
				info_sub  => $self->{parser}->can( "parse_novel" ),
				item_list_sub =>  $self->{parser}->can( "parse_item_list" ),
				item_sub      => $self->{parser}->can( "parse_novel_item" ),
				next_page_sub => $self->{parser}->can( "generate_next_page_url" ),
				%o,
		);

		#$r->{item_num}  = $max_item_num || undef;

	} ## end else [ if ( $index_url !~ /^https?:/)]

	( $r->{item_list}, $r->{item_num} ) = $self->{parser}->update_item_list( $r->{item_list}, $index_url );
	$self->{parser}->filter_item_list( $r, %o );

	for my $k ( qw/writer book/ ) {
		$r->{$k} = $o{$k} if ( exists $o{$k} );
		$r->{$k} = $self->{parser}->tidy_string( $r->{$k} );
	}

	return $r;
} ## end sub get_novel_ref

sub get_novel_items {
	my ( $self, $url, %o ) = @_;

	if($o{url_sub}){
		($url, $o{post_data}) = $o{url_sub}->($self->{parser}, $url, $o{post_data});
	}

	my $html = $self->{browser}->request_url( $url, $o{post_data} );
	my $current_page_url = $url;

	my $info      = $o{info_sub}->( $self->{parser}, \$html )     || {};
	my $item_list = $o{item_list} || $o{item_list_sub}->( $self->{parser}, \$html ) || [];

	my $i = 1;
	unless ( $o{stop_sub} and $o{stop_sub}->( $self->{parser}, $info, $item_list, $i, %o ) or defined $o{item_list}) {
		$item_list = [] if ( $o{min_page_num} and $o{min_page_num} > 1 );
		my $page_list = exists $o{page_list_sub} ? $o{page_list_sub}->( \$html ) : undef;
		my %seen_page = ( $current_page_url => 1 );
		while ( 1 ) {
			$i++;
			my $u = 
			$page_list ?  $page_list->[ $i - 2 ] : 
			( exists $o{next_page_sub} ? $o{next_page_sub}->( $self->{parser}, $current_page_url, $i, \$html ) : undef );
			last unless ( $u );
			last if ( $o{max_page_num} and $i > $o{max_page_num} );


			my ( $u_url, $u_post_data ) = ref( $u ) eq 'HASH' ? @{$u}{qw/url post_data/} : ( $u, undef );
			$u_url = $self->{parser}->generate_abs_url( $u_url, $current_page_url );
			last if ( !$u_url or $seen_page{$u_url}++ );
			my $c = $self->{browser}->request_url( $u_url, $u_post_data );
			last unless ( $c );
			$current_page_url = $u_url;
			$html = $c;
			next if ( $o{min_page_num} and $i < $o{min_page_num} );
			my $fs = $o{item_list_sub}->( $self->{parser}, \$c );
			last unless ( $fs );

			push @$item_list, @$fs;
			last if ( $o{stop_sub} and $o{stop_sub}->( $self->{parser}, $info, $item_list, $i, %o ) );
		}
	} ## end unless ( $o{stop_sub} and ...)

	#lofter倒序
	if ( $o{reverse_item_list} ){
		$item_list = [ reverse @$item_list ];
		my $max_id = $item_list->[0]{id};
		if($max_id){
			$_->{id} = $max_id - $_->{id} +1 for(@$item_list);
		}
	}
	$info->{item_num} = ( $#$item_list >= 0 and exists $item_list->[-1]{id} ) ? $item_list->[-1]{id} : ( scalar( @$item_list ) || $i );

	if ( $o{item_sub} ) {
		my @download_indexes = grep {
			my $id = $item_list->[$_]{id} // ( $_ + 1 );
			$self->{parser}->is_item_in_range( $id, $o{min_item_num}, $o{max_item_num} )
				and ( !exists $o{back_index} or $_ + $o{back_index} <= $#$item_list );
		} ( 0 .. $#$item_list );
		my $download_total = scalar @download_indexes;
		my $progress_done = 0;
		my $progress;
		if ( $o{progress} ) {
			my $writer = $info->{writer} // '';
			my $book = $info->{book} // $info->{title} // '';
			print "writer: $writer\nbook: $book\nnum: $download_total\n";
			$progress = Term::ProgressBar->new( { count => $download_total } )
				if ( $download_total );
		}

		for my $i ( 0 .. $#$item_list ) {
			my $r = $item_list->[$i];
			$r->{id} //= $i + 1;

			#$r->{url} = URI->new_abs( $r->{url}, $url )->as_string;
			$r->{url} = $self->{parser}->generate_abs_url( $r->{url}, $url );

			next unless ( $self->{parser}->is_item_in_range( $r->{id}, $o{min_item_num}, $o{max_item_num} ) );
			if(exists $o{back_index}){
				last if($i + $o{back_index} > $#$item_list);
			}

			if($r->{url}){
				my $c = $self->{browser}->request_url( $r->{url}, $r->{post_data} );
				my $temp_r = $o{item_sub}->( $self->{parser}, \$c );
				$r->{$_} //= $temp_r->{$_} for keys(%$temp_r);
			}else{
				$r = $o{item_sub}->( $self->{parser}, $r );
			}

			#my $next_url = URI->new_abs( $item_list->[$i+1]->{url}, $url )->as_string;
			my $next_url = $self->{parser}->generate_abs_url( $item_list->[$i+1]->{url}, $url );
			while($r->{next_url}){
				#$r->{next_url} = URI->new_abs( $r->{next_url}, $url )->as_string;
				$r->{next_url} = $self->{parser}->generate_abs_url( $r->{next_url}, $url );
				if($r->{next_url} ne $next_url){
					my $c = $self->{browser}->request_url( $r->{next_url}, $r->{post_data} );
					my $temp_r = $o{item_sub}->( $self->{parser}, \$c );
					$r->{content} .= "\n\n".$temp_r->{content};
					last unless(exists $temp_r->{next_url});
					$r->{next_url} = $temp_r->{next_url};
				}else{
					last;
				}
			}

			$progress->update( ++$progress_done ) if ( $progress );
		}

	}

	$info->{url} = $url;
	$info->{item_list} = $item_list || [];
	$info->{writer_url} = $self->{parser}->generate_abs_url( $info->{writer_url}, $url );

	print "\n\n" if ( $o{progress} );

	return $info;
} ## end sub get_novel_items

sub get_tiezi_ref {
	my ( $self, $url, %o ) = @_;

	my  $topic  = $self->get_novel_items(
		$url,
		info_sub  => $self->{parser}->can( "parse_novel" ),
		item_list_sub      => $self->{parser}->can( "parse_novel_item" ),
		page_list_sub =>  $self->{parser}->can( "parse_novel_list" ),
		stop_sub => sub {
			my ( $info, $data_list, $i ) = @_;
			$self->{parser}->is_list_overflow( $data_list, $o{"max_item_num"} );
		},
		%o,
	);

	$topic->{item_list} = $self->{parser}->update_item_list( $topic->{item_list}, $url );

	unshift @{$topic->{item_list}}, $topic if ( $topic->{content} );
	my %r = (
		%$topic,
		url       => $url,
		writer => $o{writer} || $topic->{writer},
		book   => $o{book}   || $topic->{book} || $topic->{title},
	);
	$self->filter_item_list( \%r, %o );

	return \%r;
} ## end sub get_tiezi_ref

sub get_page_ref {
	my ( $self, $url, %o ) = @_;

	my ( $c ) = $self->{browser}->request_url($url);
	my $r = $self->{parser}->parse_novel_item( \$c );

	my $page= {
		writer => $o{writer}, 
		book => $o{book}, 
		url => $url, 
		item_list => [ $r ], 
	};

	return $page;
}

sub get_board_ref {
	my ( $self, $board_url, %o ) = @_;

	my $html = $self->{browser}->request_url( $board_url );
	return unless ( $html );

	my $info = $self->{parser}->parse_board( \$html ) || {};
	my @items;
	push @items, @{ $self->{parser}->parse_board_item( \$html ) || [] }
		unless ( $o{min_page_num} and $o{min_page_num} > 1 );

	if ( my $parse_board_list = $self->{parser}->can( "parse_board_list" ) ) {
		my $page_urls = $parse_board_list->( $self->{parser}, \$html ) || [];
		my $page_num = 1;
		for my $page_url ( @$page_urls ) {
			$page_num++;
			next if ( $o{min_page_num} and $page_num < $o{min_page_num} );
			last if ( $o{max_page_num} and $page_num > $o{max_page_num} );

			my $page_html = $self->{browser}->request_url( $page_url );
			last unless ( $page_html );
			push @items, @{ $self->{parser}->parse_board_item( \$page_html ) || [] };
			last if ( $self->{parser}->is_list_overflow( \@items, $o{max_item_num} ) );
		}
	}

	my ( $item_list, $item_num ) = $self->{parser}->update_item_list( \@items, $board_url );
	$item_list = [ grep {
		$self->{parser}->is_item_in_range( $_->{id}, $o{min_item_num}, $o{max_item_num} )
	} @$item_list ];
	$_->{writer} //= $info->{writer} for @$item_list;

	return {
		%$info,
		url       => $board_url,
		item_num  => $item_num,
		item_list => $item_list,
	};
}


#sub extract_elements {
#    my ( $self, $h, %o ) = @_;
#    $o{path} ||= {};
#
#    my $r = {};
#    while ( my ( $xk, $xr ) = each %{ $o{path} } ) {
#        $r->{$xk} = $self->scrape_element( $h, $xr );
#    }
#    $r = $o{sub}->( $self, $h, $r ) if ( $o{sub} );
#    return $r;
#}

1;
