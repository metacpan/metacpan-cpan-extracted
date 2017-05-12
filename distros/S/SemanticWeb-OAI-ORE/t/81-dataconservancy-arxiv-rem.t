#!perl -T
#
# Test code related to resource maps in RDF/XML for Data Conservancy and dummy
# arXiv parsing library t/lib/arxiv_rem.t
#
# $Id: 81-dataconservancy-arxiv-rem.t,v 1.5 2010-12-06 14:44:02 simeon Exp $
use strict;

use warnings;

use lib qw(t/lib);

use Test::More;
plan('tests'=>32);

use_ok( 'arxiv_rem' );
use_ok( 'SemanticWeb::OAI::ORE::RDFXML' );
use_ok( 'SemanticWeb::OAI::ORE::Constant' );

use SemanticWeb::OAI::ORE::Constant qw(:all);

{
  my $rem=arxiv_rem->new('debug'=>1);
  my $file="t/examples/data_conservancy/ResourceMap1.xml";
  ok( $rem->parsefile('rdfxml',$file), "Parse $file as RDF/XML");

  # Look at the data that arXiv would need

  my $ttitle="A simple title";
  my $tauthors="Y. Fukui (Nagoya University), A. Kawamura (Nagoya University), T. Minamidani (Nagoya University)";
  my $tabstract="A simple, but useless, abstract.";
  my $tcategories="astro-ph.CO astro-ph.HE astro-ph.SR";
  my $tfiles={'ms.tex'=>{type=>'tex'},'README'=>{},'jks2000-mdstringindex.ps'=>{type=>'ps'}};
  my $tdatasets={'pom.xml'=>{type=>'xml'},'moo.sgf'=>{type=>'sgf'}};
  my $tcontact='fukui@a.phys.nagoya-u.ac.jp';

  is( $rem->article_title, $ttitle, 'metadata: check title' );
  is( $rem->article_authors, $tauthors, 'metadata: check authors' );
  is( $rem->article_abstract, $tabstract, 'metadata: check abstract' );
  is( $rem->article_categories, $tcategories, 'metadata: check categories' );
  is_deeply( $rem->article_files, $tfiles, 'files: for article' );
  is_deeply( $rem->article_datasets, $tdatasets, 'files: datasets' );
  is( $rem->article_contact_email, $tcontact, 'contact email' );
}

{
  my $rem=arxiv_rem->new('debug'=>1);
  my $file="t/examples/data_conservancy/ResourceMap2.xml";
  ok( $rem->parsefile('rdfxml',$file), "Parse $file as RDF/XML");

  my @ars=sort $rem->aggregated_resources;
  is( $ars[0], 'file:///gbfits2.fits', "check first ar: file:///gbfits2.fits");
  is( scalar(@ars), 21, "check number of ars: ");
  is( $rem->creator->name, 'datapub web app', "check ReM creator name" );
  
  # Look at the data that arXiv would need

  my $ttitle="The Second Survey of the Molecular Clouds in the Large Magellanic Cloud by NANTEN I: Catalog of Molecular Clouds";
  my $tauthors="Y. Fukui (Department of Astrophysics, Nagoya University, Furocho, Chikusaku, Nagoya 464-8602, Japan), A. Kawamura (Department of Astrophysics, Nagoya University, Furocho, Chikusaku, Nagoya 464-8602, Japan), T. Minamidani (Department of Astrophysics, Nagoya University, Furocho, Chikusaku, Nagoya 464-8602, Japan), Y. Mizuno (Department of Astrophysics, Nagoya University, Furocho, Chikusaku, Nagoya 464-8602, Japan), Y. Kanai (Department of Astrophysics, Nagoya University, Furocho, Chikusaku, Nagoya 464-8602, Japan), N. Mizuno (Department of Astrophysics, Nagoya University, Furocho, Chikusaku, Nagoya 464-8602, Japan), T. Onishi (Department of Astrophysics, Nagoya University, Furocho, Chikusaku, Nagoya 464-8602, Japan), Y. Yonekura (Department of Physical Science, Graduate School of Science, Osaka Prefecture University, 1-1 Gakuen-cho, Nakaku, Sakai, Osaka 599-8531, Japan), A. Mizuno (Solar-terrestrial Environment Laboratory, Nagoya University, Furocho, Chikusaku, Nagoya 464-8601, Japan), H. Ogawa (Department of Physical Science, Graduate School of Science, Osaka Prefecture University, 1-1 Gakuen-cho, Nakaku, Sakai, Osaka 599-8531, Japan), M. Rubio (Departamento de Astronomia, Universidad de Chile, Casilla 36-D, Santiago, Chile)";
  my $tabstract="A very short abstract";
  my $tcategories="astro-ph.CO astro-ph.HE";
  my $tfiles={'ms.tex'=>{type=>'tex'}};
  my $tdatasets={'gbfits2.fits'=>{type=>'fits'}};
  my $tcontact='fukui@a.phys.nagoya-u.ac.jp';

  is( $rem->article_title, $ttitle, 'metadata: check title' );
  is( $rem->article_authors, $tauthors, 'metadata: check authors' );
  is( $rem->article_abstract, $tabstract, 'metadata: check abstract' );
  is( $rem->article_categories, $tcategories, 'metadata: check categories' );
  is_deeply( $rem->article_files, $tfiles, 'files: for article' );
  is_deeply( $rem->article_datasets, $tdatasets, 'files: datasets' );
  is( $rem->article_contact_email, $tcontact, 'contact email' );
}

{
  my $rem=arxiv_rem->new('debug'=>1);
  my $file="t/examples/data_conservancy/ResourceMap3.xml";
  ok( $rem->parsefile('rdfxml',$file), "Parse $file as RDF/XML");
  ##print $rem->model->as_n3;

  my @ars=sort $rem->aggregated_resources;
  is( $ars[0], 'file:///gbfits2.fits', "check first ar: file:///gbfits2.fits");
  is( scalar(@ars), 5, "check number of ars: ");
  is( $rem->creator->name, 'datapub web app', "check ReM creator name" );
  
  # Look at a sample of the data that arXiv would need
  my $ttitle="The Second Survey of the Molecular Clouds";
  my $tabstract="This is an abstract";
  my $tcategories="astro-ph.IM astro-ph.HE";
  my $tfiles={'ms.tex'=>{type=>'tex'}};
  my $tdatasets={'gbfits2.fits'=>{type=>'fits'}};
  my $tcontact='fukui@a.phys.nagoya-u.ac.jp';
  is( $rem->article_title, $ttitle, 'metadata: check title' );
  is( $rem->article_abstract, $tabstract, 'metadata: check abstract' );
  is( $rem->article_categories, $tcategories, 'metadata: check categories' );
  is_deeply( $rem->article_files, $tfiles, 'files: for article' );
  is_deeply( $rem->article_datasets, $tdatasets, 'files: datasets' );
  is( $rem->article_contact_email, $tcontact, 'contact email' );
}

