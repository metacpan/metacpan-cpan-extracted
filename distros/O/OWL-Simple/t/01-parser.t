#!perl

#use lib '..\lib';
use OWL::Simple::Parser;
use File::Temp;
use Test::More tests => 8;

# turn off info for test
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $WARN );

# create temp file form _DATA_ to get a proper filename
my $fh = File::Temp->new;
$fh->printflush(
	do { local $/; <DATA> }
);

my $parser = OWL::Simple::Parser->new( owlfile => $fh->filename, 
								synonym_tag => 'efo:alternative_term',
								definition_tag => 'efo:RANDOMTAG' );

ok( $parser->parse,                'Parser loads' );
ok( $parser->version() eq '2.5classified', 'Version found' );
ok( $parser->class_count() > 0,    'Classes count' );
ok( $parser->synonyms_count() > 0, 'Synonyms count' );
ok( $parser->class->{EFO_0000616}->definitions->[0], 'Found definitions on custom tag' );
ok( !defined $parser->class->{EFO_0000304}->definitions->[0],
	'No definitions' );
ok( $parser->class->{EFO_0000616}->subClassOf->[0], 'Found child' );

# TEST the code from synopsis

	# iterate through all the classes
	for my $id (keys %{ $parser->class }){
		my $OWLClass = $parser->class->{$id};
		print $id . ' ' . $OWLClass->label . "\n";
		
		# list synonyms
		for my $syn (@{ $OWLClass->synonyms }){
			print "\tsynonym - $syn\n";
		}
		
		# list definitions
		for my $def (@{ $OWLClass->definitions }){
			print "\tdef - $def\n";
		}
		
		# list parents
		for my $parent (@{ $OWLClass->subClassOf }){
			print "\tsubClassOf - $parent\n";
		}
	}

pass('SYNOPSIS');








__DATA__
<?xml version="1.0"?>
<rdf:RDF
    xmlns:uo="http://purl.org/obo/owl/UO#"
    xmlns:chebi="http://www.ebi.ac.uk/chebi/searchId.do;?chebiId="
    xmlns:protege="http://protege.stanford.edu/plugins/owl/protege#"
    xmlns:obo="http://purl.obolibrary.org/obo/"
    xmlns:xsp="http://www.owl-ontologies.com/2005/08/07/xsp.owl#"
    xmlns:NCBITaxon="http://purl.org/obo/owl/NCBITaxon#"
    xmlns:owl2xml="http://www.w3.org/2006/12/owl2-xml#"
    xmlns:swrlb="http://www.w3.org/2003/11/swrlb#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:snap="http://www.ifomis.org/bfo/1.1/snap#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:efo="http://www.ebi.ac.uk/efo/"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
    xmlns:swrl="http://www.w3.org/2003/11/swrl#"
    xmlns:owl2="http://www.w3.org/2006/12/owl2#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns="http://www.ebi.ac.uk/efo/efo.owl"
    xmlns:span="http://www.ifomis.org/bfo/1.1/span#"
  xml:base="http://www.ebi.ac.uk/efo/efo.owl">
  <owl:Ontology rdf:about="">
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Phenotypic quality (PATO) ver1.221</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to BRENDA tissue / enzyme source (BTO) ver1.3</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Microarray experimental conditions (MO) ver1.3.1.1</rdfs:comment>
    <efo:creator rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Tomasz Adamusiak</efo:creator>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Zebrafish anatomy and development (ZFA) ver1.27</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Units of measurement (UO) ver1.27</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to SNOMED Clinical Terms (SNOMEDCT) ver2009_07_31</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to NCBI organismal classification (null) ver1.2</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to MGED Ontology (MO) ver1.3.1.1</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Human disease (DOID) ver1.192</rdfs:comment>
    <owl:versionInfo rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >2.5</owl:versionInfo>
    <owl:versionInfo rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >classified</owl:versionInfo>
    <efo:creator rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Helen Parkinson</efo:creator>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to International Classification of Diseases (ICD-9) ver9</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Mappings:The Arabidopsis Information Resource (TAIR)</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Foundational Model of Anatomy (FMA) ver3.0</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Chemical entities of biological interest (CHEBI) ver1.66</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Minimal anatomical terminology (MAT) ver1.1</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Mappings to Plant structure (PO)</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Mappings: CRISP Thesaurus Version 2.5.2.0</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Malaria Ontology (IDOMAL) ver1.1</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Date: 1st July 2010:</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Medical Subject Headings (MSH) ver2010_2009_08_17</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Mosquito gross anatomy (TGMA) ver1.10</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Gene Ontology (GO) ver1.886</rdfs:comment>
    <efo:creator rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:creator>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Mappings: The Jackson Lab</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Teleost anatomy and development (TAO) ver1.158</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to NCI Thesaurus (NCIt) ver10.01</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Drosophila gross anatomy (FBbt) ver1.33</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Mammalian phenotype (MP) ver1.347</rdfs:comment>
    <efo:creator rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Ele Holloway</efo:creator>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Ontology for Biomedical Investigations (OBI) ver2009-11-06 Philly (aka version 1.0) Release Candidate</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to NIFSTD (nif) ver1.8</rdfs:comment>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bioportal mappings to Cell type (CL) ver1.43</rdfs:comment>
  </owl:Ontology>
  <owl:Class rdf:about="http://www.ebi.ac.uk/efo/EFO_0000313">
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <rdfs:subClassOf>
      <owl:Class rdf:about="http://www.ebi.ac.uk/efo/EFO_0000311"/>
    </rdfs:subClassOf>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >carcinoma</rdfs:label>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A type of malignant cancer that arises from epithelial cells tending to infiltrate the surrounding tissues and give rise to metastases.</efo:definition>
  </owl:Class>
  <owl:Class rdf:about="http://www.ebi.ac.uk/efo/EFO_0000408">
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <rdfs:subClassOf>
      <owl:Class rdf:about="http://www.ifomis.org/bfo/1.1/snap#Disposition"/>
    </rdfs:subClassOf>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >disease</rdfs:label>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A disease is a disposition that describes states of disease associated with a particular sample and/or organism.</efo:definition>
  </owl:Class>
  <owl:Class rdf:about="http://www.ebi.ac.uk/efo/EFO_0000616">
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Neoplasia[accessedResource: NCIt:C3262][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:RANDOMTAG rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >An abnormal tissue growth resulted from uncontrolled cell proliferation. Benign neoplastic cells resemble normal cells without exhibiting significant cytologic atypia, while malignant ones exhibit overt signs such as dysplastic features, atypical mitotic figures, necrosis, nuclear pleomorphism, and anaplasia. Representative examples of benign neoplasms include papillomas, cystadenomas, and lipomas; malignant neoplasms include carcinomas, sarcomas, lymphomas, and leukemias.</efo:RANDOMTAG>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >NEOPLASMS BENIGN, MALIGNANT AND UNSPECIFIED (INCL CYSTS AND POLYPS)[accessedResource: NCIt:C3262][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:RANDOMTAG rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >An abnormal tissue growth resulted from uncontrolled cell proliferation.
</efo:RANDOMTAG>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >neoplasm</rdfs:label>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A benign or malignant tissue growth resulting from uncontrolled cell proliferation.  Benign neoplastic cells resemble normal cells without exhibiting significant cytologic atypia, while malignant cells exhibit overt signs such as dysplastic features, atypical mitotic figures, necrosis, nuclear pleomorphism, and anaplasia.  Representative examples of benign neoplasms include papillomas, cystadenomas, and lipomas; malignant neoplasms include carcinomas, sarcomas, lymphomas, and leukemias.[accessedResource: NCIt:C3262][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Neoplastic Growth</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Tumor[accessedResource: NCIt:C3262][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Neoplasms</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Neoplastic Growth[accessedResource: NCIt:C3262][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >NCIt:C3262</efo:definition_citation>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Neoplasms[accessedResource: NCIt:C3262][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Tumor</efo:alternative_term>
    <efo:RANDOMTAG rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A benign or malignant tissue growth resulting from uncontrolled cell proliferation.  Benign neoplastic cells resemble normal cells without exhibiting significant cytologic atypia, while malignant cells exhibit overt signs such as dysplastic features, atypical mitotic figures, necrosis, nuclear pleomorphism, and anaplasia.  Representative examples of benign neoplasms include papillomas, cystadenomas, and lipomas; malignant neoplasms include carcinomas, sarcomas, lymphomas, and leukemias.</efo:RANDOMTAG>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Neoplasia</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >NEOPLASMS BENIGN, MALIGNANT AND UNSPECIFIED (INCL CYSTS AND POLYPS)</efo:alternative_term>
    <rdfs:subClassOf rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000408"/>
  </owl:Class>
  <owl:Class rdf:about="http://www.ebi.ac.uk/efo/EFO_0000216">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >acinar cell carcinoma</rdfs:label>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Acinic cell adenocarcinoma</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Acinic Cell Carcinoma</efo:alternative_term>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >GeneRIF:11891193</efo:definition_citation>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Carcinomas, Acinar Cell[accessedResource: MSH:D018267][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >MSH:D018267</efo:definition_citation>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >DOID:3025</efo:definition_citation>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Acinar carcinoma[accessedResource: SNOMEDCT:45410002][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Acinar Cell Carcinomas</efo:alternative_term>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A malignant glandular epithelial neoplasm consisting of secretory cells forming acinar patterns. Representative examples include the acinar cell carcinoma of the pancreas and the acinar adenocarcinoma of the prostate gland.</efo:definition>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Acinar Adenocarcinoma</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Acinar Cell Adenocarcinoma[accessedResource: NCIt:C3768][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Acinar adenocarcinoma[accessedResource: SNOMEDCT:45410002][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Acinar Cell Adenocarcinoma</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A malignant glandular epithelial neoplasm consisting of secretory cells forming acinar patterns. Representative examples include the acinar cell carcinoma of the pancreas and the acinar adenocarcinoma of the prostate gland.[accessedResource: NCIt:C3768][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >SNOMEDCT:45410002</efo:definition_citation>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >acinar cell carcinoma (morphologic abnormality)[accessedResource: DOID:3025][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Acinic Cell Adenocarcinoma[accessedResource: NCIt:C3768][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A malignant tumor arising from secreting cells of a racemose gland, particularly the salivary glands. Racemose (Latin racemosus, full of clusters) refers, as does acinar (Latin acinus, grape), to small saclike dilatations in various glands. Acinar cell carcinomas are usually well differentiated and account for about 13% of the cancers arising in the parotid gland. Lymph node metastasis occurs in about 16% of cases. Local recurrences and distant metastases many years after treatment are common. This tumor appears in all age groups and is most common in women. (Stedman, 25th ed; Holland et al., Cancer Medicine, 3d ed, p1240; from DeVita Jr et al., Cancer: Principles &amp; Practice of Oncology, 3d ed, p575)[accessedResource: MSH:D018267][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A malignant tumor arising from secreting cells of a racemose gland, particularly the salivary glands. Racemose (Latin racemosus, full of clusters) refers, as does acinar (Latin acinus, grape), to small saclike dilatations in various glands. Acinar cell carcinomas are usually well differentiated and account for about 13% of the cancers arising in the parotid gland. Lymph node metastasis occurs in about 16% of cases. Local recurrences and distant metastases many years after treatment are common. This tumor appears in all age groups and is most common in women. (Stedman, 25th ed; Holland et al., Cancer Medicine, 3d ed, p1240; from DeVita Jr et al., Cancer: Principles &amp; Practice of Oncology, 3d ed, p575)</efo:definition>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Acinar carcinoma</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >acinar cell carcinoma (morphologic abnormality)</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Acinic Cell Carcinoma[accessedResource: NCIt:C3768][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <rdfs:subClassOf rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000313"/>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >NCIt:C3768</efo:definition_citation>
  </owl:Class>
  <owl:Class rdf:about="http://www.ebi.ac.uk/efo/EFO_0000001">
    <efo:creator rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Helen Parkinson</efo:creator>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >MO_10</efo:definition_citation>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Helen Parkinson</efo:definition_editor>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Tomasz Adamusiak</efo:definition_editor>
    <efo:creator rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Tomasz Adamusiak</efo:creator>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Concept naming convention is lower case natural naming with spaces, when necessary captials should be used, for example disease factor, HIV, breast carcinoma, Ewing's sarcoma</rdfs:comment>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Jie Zheng</efo:definition_editor>
    <efo:description rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >An experimental factor in Array Express.</efo:description>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >An experimental factor in Array Express which are essentially the variable aspects of an experiment design which can be used to describe an experiment, or set of experiments, in an increasingly detailed manner.</efo:definition>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <efo:creator rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:creator>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >experimental factor</rdfs:label>
    <efo:organizational_class rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >true</efo:organizational_class>
  </owl:Class>
  <owl:Class rdf:about="http://www.ebi.ac.uk/efo/EFO_0000311">
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Tomasz Adamusiak</efo:definition_editor>
    <efo:branch_class rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >true</efo:branch_class>
    <rdfs:subClassOf rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000616"/>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >malignant tumor</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >malignant neoplasia</efo:alternative_term>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >malignant tumour</efo:alternative_term>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >cancer</rdfs:label>
    <efo:example_of_usage rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >ductal carcinoma in situ</efo:example_of_usage>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >NIFSTD:birnlex_406</efo:definition_citation>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A malignant neoplasm in which new abnormal tissue grow by excessive cellular division and proliferation more rapidly than normal and continues to grow after the stimuli that initiated the new growth cease.</efo:definition>
  </owl:Class>
  <owl:Class rdf:about="http://www.ebi.ac.uk/efo/EFO_0000304">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >breast adenocarcinoma</rdfs:label>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <rdfs:subClassOf>
      <owl:Class rdf:about="http://www.ebi.ac.uk/efo/EFO_0000228"/>
    </rdfs:subClassOf>
  </owl:Class>
  <owl:Class rdf:about="http://www.ebi.ac.uk/efo/EFO_0000348">
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >DOID:4468</efo:definition_citation>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >[M]Clear cell adenocarcinoma NOS</efo:alternative_term>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >GeneRIF:15102668</efo:definition_citation>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >SNOMEDCT:189633003</efo:definition_citation>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >GeneRIF:15884099</efo:definition_citation>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >clear cell adenocarcinoma</rdfs:label>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >GeneRIF:12937142</efo:definition_citation>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Mesonephroid Clear Cell Carcinoma</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >clear cell carcinoma</efo:alternative_term>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >An adenocarcinoma characterized by the presence of varying combinations of clear and hobnail-shaped tumor cells. There are three predominant patterns described as tubulocystic, solid, and papillary. These tumors, usually located in the female reproductive organs, have been seen more frequently in young women since 1970 as a result of the association with intrauterine exposure to diethylstilbestrol. (From Holland et al., Cancer Medicine, 3d ed)</efo:definition>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Mesonephroid clear cell adenocarcinoma[accessedResource: SNOMEDCT:30546008][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >[M]Clear cell adenocarcinoma NOS[accessedResource: SNOMEDCT:189633003][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >GeneRIF:14559803</efo:definition_citation>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A malignant neoplasm composed of glandular epithelial clear cells.  Various architectural patterns may be seen, including papillary, tubulocystic, and solid.
</efo:definition>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Mesonephroid Clear cell carcinoma[accessedResource: DOID:4468][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A malignant neoplasm composed of glandular epithelial clear cells.  Various architectural patterns may be seen, including papillary, tubulocystic, and solid.[accessedResource: NCIt:C3766][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >MSH:D018262</efo:definition_citation>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Clear cell adenocarcinoma NOS (morphologic abnormality)[accessedResource: DOID:4468][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Clear cell adenocarcinoma, NOS</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Adenocarcinomas, Clear Cell[accessedResource: MSH:D018262][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Clear cell adenocarcinoma, NOS[accessedResource: SNOMEDCT:30546008][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >[M]Clear cell adenocarcinoma NOS (morphologic abnormality)</efo:alternative_term>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >GeneRIF:15297970</efo:definition_citation>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >GeneRIF:12086860</efo:definition_citation>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >An adenocarcinoma characterized by the presence of varying combinations of clear and hobnail-shaped tumor cells. There are three predominant patterns described as tubulocystic, solid, and papillary. These tumors, usually located in the female reproductive organs, have been seen more frequently in young women since 1970 as a result of the association with intrauterine exposure to diethylstilbestrol. (From Holland et al., Cancer Medicine, 3d ed)[accessedResource: MSH:D018262][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Clear cell adenocarcinoma (morphologic abnormality)[accessedResource: DOID:4468][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >GeneRIF:12970394</efo:definition_citation>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Clear cell adenocarcinoma NOS (morphologic abnormality)</efo:alternative_term>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >GeneRIF:14729622</efo:definition_citation>
    <rdfs:subClassOf>
      <owl:Class rdf:about="http://www.ebi.ac.uk/efo/EFO_0000228"/>
    </rdfs:subClassOf>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Clear cell adenocarcinoma (morphologic abnormality)</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Mesonephroid clear cell adenocarcinoma</efo:alternative_term>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >GeneRIF:14722919</efo:definition_citation>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >SNOMEDCT:30546008</efo:definition_citation>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >NCIt:C3766</efo:definition_citation>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Clear cell carcinoma[accessedResource: SNOMEDCT:30546008][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >GeneRIF:15489654</efo:definition_citation>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >GeneRIF:14633622</efo:definition_citation>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Clear Cell Adenocarcinomas</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >[M]Clear cell adenocarcinoma NOS (morphologic abnormality)[accessedResource: SNOMEDCT:189633003][accessDate: 10-05-2010]</efo:bioportal_provenance>
  </owl:Class>
  <owl:Class rdf:about="http://www.ebi.ac.uk/efo/EFO_0000228">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >adenocarcinoma</rdfs:label>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A type of carcinoma derived from glandular tissue or in which tumor cells form recognizable glandular structures.</efo:definition>
    <rdfs:subClassOf rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000313"/>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >CRISP Thesaurus 2006, Term Number 2000-0386, http://crisp.cit.nih.gov/Thesaurus/00000107.htm Date accessed: 1st Novemeber 2007</efo:definition_citation>
  </owl:Class>
  <owl:Class rdf:about="http://www.ebi.ac.uk/efo/EFO_0001416">
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Adenocarcinoma of Cervix Uteri[accessedResource: NCIt:C4029][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Adenocarcinoma of Cervix[accessedResource: NCIt:C4029][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Adenocarcinoma of Cervix Uteri</efo:alternative_term>
    <rdfs:subClassOf rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000228"/>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Cervix Adenocarcinoma</efo:alternative_term>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >cervical adenocarcinoma</rdfs:label>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >DOID:3702</efo:definition>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >NCIt:C4029</efo:definition_citation>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >An adenocarcinoma arising from the cervical epithelium.  It accounts for approximately 15% of invasive cervical carcinomas.  Increased numbers of sexual partners and human papilloma virus (HPV) infection are risk factors.  Grossly, advanced cervical adenocarcinoma may present as an exophytic mass, an ulcerated lesion, or diffuse cervical enlargement.  Microscopically, the majority of cervical adenocarcinomas are of the endocervical (mucinous) type.</efo:definition>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Adenocarcinoma of the Cervix Uteri</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Cervix Uteri Adenocarcinoma[accessedResource: NCIt:C4029][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Adenocarcinoma of the Cervix Uteri[accessedResource: NCIt:C4029][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Cervix Adenocarcinoma[accessedResource: NCIt:C4029][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Adenocarcinoma of the Cervix</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >An adenocarcinoma arising from the cervical epithelium.  It accounts for approximately 15% of invasive cervical carcinomas.  Increased numbers of sexual partners and human papilloma virus (HPV) infection are risk factors.  Grossly, advanced cervical adenocarcinoma may present as an exophytic mass, an ulcerated lesion, or diffuse cervical enlargement.  Microscopically, the majority of cervical adenocarcinomas are of the endocervical (mucinous) type.[accessedResource: NCIt:C4029][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Adenocarcinoma of the Uterine Cervix</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Adenocarcinoma of the Cervix[accessedResource: NCIt:C4029][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Adenocarcinoma of Uterine Cervix[accessedResource: NCIt:C4029][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Uterine Cervix Adenocarcinoma[accessedResource: NCIt:C4029][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Adenocarcinoma of Uterine Cervix</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Adenocarcinoma of the Uterine Cervix[accessedResource: NCIt:C4029][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Cervix Uteri Adenocarcinoma</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Adenocarcinoma of Cervix</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Uterine Cervix Adenocarcinoma</efo:alternative_term>
  </owl:Class>
  <owl:Class rdf:about="http://www.ebi.ac.uk/efo/EFO_0000308">
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >MSH:D002282</efo:definition_citation>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolo-alveolar adenocarcinoma (morphologic abnormality)[accessedResource: SNOMEDCT:112677002][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioloalveolar Adenocarcinoma of the Lung[accessedResource: NCIt:C2923][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Carcinoma, Bronchiolar[accessedResource: MSH:D002282][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Alveolar adenocarcinoma (morphologic abnormality)</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Alveolar Adenocarcinomas</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >[M]Bronchiolo-alveolar adenocarcinoma[accessedResource: SNOMEDCT:112677002][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioloalveolar Carcinomas[accessedResource: MSH:D002282][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolo-Alveolar Carcinoma of Lung</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioloalveolar carcinoma - disorder</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolo-Alveolar Carcinoma</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Carcinomas, Bronchiolo-Alveolar[accessedResource: MSH:D002282][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioloalveolar Lung Adenocarcinoma</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolo-Alveolar Adenocarcinomas[accessedResource: MSH:D002282][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >[M]Bronchiolo-alveolar adenocarcinoma</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Alveolar Adenocarcinoma[accessedResource: MSH:D002282][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioalveolar Adenocarcinoma of Lung[accessedResource: NCIt:C2923][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A carcinoma thought to be derived from epithelium of terminal bronchioles, in which the neoplastic tissue extends along the alveolar walls and grows in small masses within the alveoli. Involvement may be uniformly diffuse and massive, or nodular, or lobular. The neoplastic cells are cuboidal or columnar and form papillary structures. Mucin may be demonstrated in some of the cells and in the material in the alveoli, which also includes denuded cells. Metastases in regional lymph nodes, and in even more distant sites, are known to occur, but are infrequent. (From Stedman, 25th ed)</efo:definition>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A well or moderately differentiated morphologic variant of lung adenocarcinoma characterized by tumor growth along the alveolar structures without stromal, vascular, or pleural invasion.[accessedResource: NCIt:C2923][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A carcinoma thought to be derived from epithelium of terminal bronchioles, in which the neoplastic tissue extends along the alveolar walls and grows in small masses within the alveoli. Involvement may be uniformly diffuse and massive, or nodular, or lobular. The neoplastic cells are cuboidal or columnar and form papillary structures. Mucin may be demonstrated in some of the cells and in the material in the alveoli, which also includes denuded cells. Metastases in regional lymph nodes, and in even more distant sites, are known to occur, but are infrequent. (From Stedman, 25th ed)[accessedResource: MSH:D002282][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolo-Alveolar Carcinoma[accessedResource: MSH:D002282][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Carcinoma, Bronchioloalveolar[accessedResource: MSH:D002282][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Carcinomas, Bronchioloalveolar</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Alveolar Carcinomas</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioloalveolar adenocarcinoma</efo:alternative_term>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >SNOMEDCT:373627005</efo:definition_citation>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Carcinomas, Bronchiolo-Alveolar</efo:alternative_term>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >SNOMEDCT:112677002</efo:definition_citation>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Alveolar Carcinomas[accessedResource: MSH:D002282][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolo-Alveolar Lung Carcinoma[accessedResource: NCIt:C2923][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Alveolar Adenocarcinomas[accessedResource: MSH:D002282][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolo-alveolar adenocarcinoma[accessedResource: SNOMEDCT:112677002][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Carcinomas, Bronchiolar</efo:alternative_term>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >NCIt:C2923</efo:definition_citation>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolo-Alveolar Lung Carcinoma</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >BAC[accessedResource: NCIt:C2923][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolo-Alveolar Carcinoma of the Lung</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioloalveolar adenocarcinoma[accessedResource: DOID:4926][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >BAC</efo:alternative_term>
    <rdfs:subClassOf rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000228"/>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioloalveolar Adenocarcinoma of Lung</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioalveolar Adenocarcinoma of Lung</efo:alternative_term>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolo-Alveolar Carcinoma of Lung[accessedResource: NCIt:C2923][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolo-Alveolar Adenocarcinomas</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioalveolar Lung Carcinoma</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Alveolar cell carcinoma[accessedResource: SNOMEDCT:112677002][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Alveolar adenocarcinoma (morphologic abnormality)[accessedResource: SNOMEDCT:36310008][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioloalveolar Lung Adenocarcinoma[accessedResource: NCIt:C2923][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioloalveolar Carcinoma</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioalveolar Adenocarcinoma of the Lung[accessedResource: NCIt:C2923][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolar carcinoma</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioalveolar Lung Carcinoma[accessedResource: NCIt:C2923][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >bronchoalveolar adenocarcinoma</rdfs:label>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Alveolar cell carcinoma</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >bronchiolo-alveolar adenocarcinoma</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Alveolar Adenocarcinoma</efo:alternative_term>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A well or moderately differentiated morphologic variant of lung adenocarcinoma characterized by tumor growth along the alveolar structures without stromal, vascular, or pleural invasion.
</efo:definition>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolo-Alveolar Carcinoma of the Lung[accessedResource: NCIt:C2923][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolar Carcinomas[accessedResource: MSH:D002282][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Alveolar carcinoma[accessedResource: SNOMEDCT:36310008][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioloalveolar Adenocarcinoma of the Lung</efo:alternative_term>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >DOID:4926</efo:definition_citation>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioloalveolar Adenocarcinoma of Lung[accessedResource: NCIt:C2923][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioloalveolar carcinoma (disorder)[accessedResource: DOID:4926][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchioalveolar Adenocarcinoma of the Lung</efo:alternative_term>
    <efo:bioportal_provenance rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolar adenocarcinoma[accessedResource: SNOMEDCT:112677002][accessDate: 10-05-2010]</efo:bioportal_provenance>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Alveolar Carcinoma</efo:alternative_term>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolo-alveolar adenocarcinoma (morphologic abnormality)</efo:alternative_term>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >SNOMEDCT:36310008</efo:definition_citation>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Bronchiolar adenocarcinoma</efo:alternative_term>
  </owl:Class>
  <owl:Class rdf:about="http://purl.obolibrary.org/obo/OBI_0000245">
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Jie Zheng</efo:definition_editor>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >organization</rdfs:label>
    <rdfs:subClassOf>
      <owl:Class rdf:about="http://www.ifomis.org/bfo/1.1/snap#MaterialEntity"/>
    </rdfs:subClassOf>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >An organization is a continuant entity which can play roles,  has members, and has a set of organization rules.  Members of organizations are either organizations themselves or individual people. Members can bear specific organization member roles that are determined in the organization rules. The organization rules also determine how decisions are made on behalf of the organization by the organization members.</efo:definition>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >MO_177</efo:definition_citation>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >organisation</efo:alternative_term>
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/EFO_0002010</efo:EFO_URI>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Tomasz Adamusiak</efo:definition_editor>
  </owl:Class>
  <owl:Class rdf:about="http://www.ifomis.org/bfo/1.1/snap#MaterialEntity">
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A material entity is an entity that exists in full during the length of time of its existence, persists through this time while maintaining its identity and has no temporal parts. For example a heart, a human, a fly, a microarray.</efo:definition>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >material entity</rdfs:label>
    <efo:source_definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >An independent continuant [snap:IndependentContinuant] that is spatially extended whose identity is independent of that of other entities and can be maintained through time. Note: Material entity [snap:MaterialEntity] subsumes object [snap:Object], fiat object part [snap:FiatObjectPart], and object aggregate [snap:ObjectAggregate], which assume a three level theory of granularity, which is inadequate for some domains, such as biology.</efo:source_definition>
    <efo:organizational_class rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >true</efo:organizational_class>
    <efo:ArrayExpress_label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >sample factor</efo:ArrayExpress_label>
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/EFO_0001434</efo:EFO_URI>
    <efo:example_of_usage rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A heart, a human, a fly, a microarray.</efo:example_of_usage>
    <rdfs:subClassOf rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000001"/>
  </owl:Class>
  <owl:Class rdf:about="http://www.ifomis.org/bfo/1.1/snap#SpecificallyDependentContinuant">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >material property</rdfs:label>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    ></rdfs:comment>
    <efo:alternative_term rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >SpecificallyDependentContinuant</efo:alternative_term>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <efo:organizational_class rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >true</efo:organizational_class>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >An experimental factor which is a property or characteristic of some other entity.  For example, the mouse has the colour white.</efo:definition>
    <efo:ArrayExpress_label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >sample characteristic</efo:ArrayExpress_label>
    <efo:source_definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A continuant [snap:Continuant] that inheres in or is borne by other entities. Every instance of A requires some specific instance of B which must always be the same.</efo:source_definition>
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/EFO_0001443</efo:EFO_URI>
    <rdfs:subClassOf rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000001"/>
  </owl:Class>
  <owl:Class rdf:about="http://www.ifomis.org/bfo/1.1/snap#Disposition">
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <efo:source_definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A realizable entity [snap:RealizableEntity] that essentially causes a specific process or transformation in the object [snap:Object] in which it inheres, under specific circumstances and in conjunction with the laws of nature. A general formula for dispositions is: X (object [snap:Object] has the disposition D to (transform, initiate a process) R under conditions C.</efo:source_definition>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    ></rdfs:comment>
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/EFO_0001438</efo:EFO_URI>
    <efo:example_of_usage rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >For example, the disposition of vegetables to decay when not refrigerated, the disposition of blood to coagulate, the disposition of a patient with a weakened immune system to contract disease.</efo:example_of_usage>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A disposition is an entity that essentially causes a specific process or transformation in an entity in which it inheres, under specific circumstances and in conjunction with the laws of nature. For example, the disposition of vegetables to decay when not refrigerated, the disposition of blood to coagulate, the disposition of a patient with a weakened immune system to contract disease.</efo:definition>
    <efo:ArrayExpress_label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >disease property</efo:ArrayExpress_label>
    <efo:branch_class rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >true</efo:branch_class>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >disposition</rdfs:label>
    <rdfs:subClassOf rdf:resource="http://www.ifomis.org/bfo/1.1/snap#SpecificallyDependentContinuant"/>
  </owl:Class>
  <owl:ObjectProperty rdf:about="http://purl.obolibrary.org/obo/OBI_0000295">
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    ></rdfs:comment>
    <rdfs:domain rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000001"/>
    <rdfs:subPropertyOf>
      <owl:ObjectProperty rdf:about="http://www.obofoundry.org/ro/ro.owl#participates_in"/>
    </rdfs:subPropertyOf>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >is_input_of</rdfs:label>
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/is_input_of</efo:EFO_URI>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.obofoundry.org/ro/ro.owl#contained_in">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >contained_in</rdfs:label>
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/contained_in</efo:EFO_URI>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Containment obtains in each case between material and immaterial continuants, for instance: lung contained_in thoracic cavity; bladder contained_in pelvic cavity. Hence containment is not a transitive relation. If c part_of c1 at t then we have also, by our definition and by the axioms of mereology applied to spatial regions, c located_in c1 at t. Thus, many examples of instance-level location relations for continuants are in fact cases of instance-level parthood. For material continuants location and parthood coincide. Containment is location not involving parthood, and arises only where some immaterial continuant is involved. To understand this relation, we first define overlap for continuants as follows: c1 overlap c2 at t =def for some c, c part_of c1 at t and c part_of c2 at t.</efo:definition>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.obofoundry.org/ro/ro.owl#location_of">
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/location_of</efo:EFO_URI>
    <owl:inverseOf>
      <owl:ObjectProperty rdf:about="http://www.obofoundry.org/ro/ro.owl#located_in"/>
    </owl:inverseOf>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >location_of</rdfs:label>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://purl.obolibrary.org/obo/OBI_0000308">
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    ></rdfs:comment>
    <owl:inverseOf>
      <owl:ObjectProperty rdf:about="http://purl.obolibrary.org/obo/OBI_0000300"/>
    </owl:inverseOf>
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/realizes</efo:EFO_URI>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >realizes</rdfs:label>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Relation between a process and a material fulfilling a role (i.e. realizing a role within the context of the process).  For example a human realizing role of teacher within a lesson teching process.</efo:definition>
    <rdfs:range rdf:resource="http://www.ifomis.org/bfo/1.1/snap#SpecificallyDependentContinuant"/>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_0000785">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >is_location_of_disease</rdfs:label>
    <rdfs:subPropertyOf>
      <owl:ObjectProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_0000824"/>
    </rdfs:subPropertyOf>
    <rdfs:range rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000408"/>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://purl.obolibrary.org/obo/OBI_0000293">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >has_input</rdfs:label>
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/has_input</efo:EFO_URI>
    <owl:inverseOf rdf:resource="http://purl.obolibrary.org/obo/OBI_0000295"/>
    <rdfs:range rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000001"/>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    ></rdfs:comment>
    <rdfs:subPropertyOf>
      <owl:ObjectProperty rdf:about="http://www.obofoundry.org/ro/ro.owl#has_participant"/>
    </rdfs:subPropertyOf>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://purl.org/obo/owl/OBO_REL#inheres_in">
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/EFO_0000829</efo:EFO_URI>
    <rdfs:domain rdf:resource="http://www.ifomis.org/bfo/1.1/snap#SpecificallyDependentContinuant"/>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >inheres_in</rdfs:label>
    <rdfs:range rdf:resource="http://www.ifomis.org/bfo/1.1/snap#MaterialEntity"/>
    <owl:inverseOf>
      <owl:ObjectProperty rdf:about="http://purl.org/obo/owl/OBO_REL#bearer_of"/>
    </owl:inverseOf>
    <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#FunctionalProperty"/>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://purl.org/obo/owl/OBO_REL#bearer_of">
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/EFO_0001377</efo:EFO_URI>
    <rdfs:domain rdf:resource="http://www.ifomis.org/bfo/1.1/snap#MaterialEntity"/>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    ></rdfs:comment>
    <rdfs:range rdf:resource="http://www.ifomis.org/bfo/1.1/snap#SpecificallyDependentContinuant"/>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A relation between an entity and a dependent continuant; the reciprocal relation of inheres_in [GOC:cjm] example of usage: red eye bearer_of redness</efo:definition>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >bearer_of</rdfs:label>
    <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#InverseFunctionalProperty"/>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_0001697">
    <rdfs:subPropertyOf>
      <owl:ObjectProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_0000824"/>
    </rdfs:subPropertyOf>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >is_unit_of</rdfs:label>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.obofoundry.org/ro/ro.owl#derives_from">
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/derives_from</efo:EFO_URI>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >derives_from</rdfs:label>
    <owl:inverseOf>
      <owl:ObjectProperty rdf:about="http://www.obofoundry.org/ro/ro.owl#derived_into"/>
    </owl:inverseOf>
    <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#TransitiveProperty"/>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Derivation as a relation between instances. The temporal relation of derivation is more complex. Transformation, on the instance level, is just the relation of identity: each adult is identical to some child existing at some earlier time. Derivation on the instance-level is a relation holding between non-identicals. More precisely, it holds between distinct material continuants when one succeeds the other across a temporal divide in such a way that at least a biologically significant portion of the matter of the earlier continuant is inherited by the later. Thus we will have axioms to the effect that from c derives_from c1 we can infer that c and c1 are not identical and that there is some instant of time t such that c1 exists only prior to and c only subsequent to t. We will also be able to infer that the spatial region occupied by c as it begins to exist at t overlaps with the spatial region occupied by c1 as it ceases to exist in the same instant.</efo:definition>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_0000784">
    <rdfs:domain rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000408"/>
    <owl:inverseOf rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000785"/>
    <rdfs:subPropertyOf>
      <owl:ObjectProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_0000824"/>
    </rdfs:subPropertyOf>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >has_disease_location</rdfs:label>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_0000794">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >is_broader_than</rdfs:label>
    <rdfs:subPropertyOf>
      <owl:ObjectProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_0000824"/>
    </rdfs:subPropertyOf>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.obofoundry.org/ro/ro.owl#contains">
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/contains</efo:EFO_URI>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >contains</rdfs:label>
    <owl:inverseOf rdf:resource="http://www.obofoundry.org/ro/ro.owl#contained_in"/>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.obofoundry.org/ro/ro.owl#participates_in">
    <owl:inverseOf>
      <owl:ObjectProperty rdf:about="http://www.obofoundry.org/ro/ro.owl#has_participant"/>
    </owl:inverseOf>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Participates in is a primitive instance-level relation between a continuant and a process in which it participates. For example a scanner participates in a scanning process at some specific time.</efo:definition>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >participates_in</rdfs:label>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.obofoundry.org/ro/ro.owl#part_of">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >part_of</rdfs:label>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >For continuants: C part_of C' if and only if: given any c that instantiates C at a time t, there is some c' such that c' instantiates C' at time t, and c *part_of* c' at t. For processes: P part_of P' if and only if: given any p that instantiates P at a time t, there is some p' such that p' instantiates P' at time t, and p *part_of* p' at t. (Here *part_of* is the instance-level part-relation.)</efo:definition>
    <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#TransitiveProperty"/>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >EFO_0000822</rdfs:comment>
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/part_of</efo:EFO_URI>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.obofoundry.org/ro/ro.owl#derived_into">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >derived_into</rdfs:label>
    <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#TransitiveProperty"/>
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/derived_into</efo:EFO_URI>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_0000741">
    <owl:inverseOf>
      <owl:ObjectProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_0000742"/>
    </owl:inverseOf>
    <rdfs:domain rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000311"/>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >has_tumor_type</rdfs:label>
    <rdfs:subPropertyOf>
      <owl:ObjectProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_0000824"/>
    </rdfs:subPropertyOf>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.obofoundry.org/ro/ro.owl#has_part">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >has_part</rdfs:label>
    <owl:inverseOf rdf:resource="http://www.obofoundry.org/ro/ro.owl#part_of"/>
    <rdfs:comment rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >EFO_0000823</rdfs:comment>
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/has_part</efo:EFO_URI>
    <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#TransitiveProperty"/>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://purl.obolibrary.org/obo/OBI_0000300">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >is_realized_by</rdfs:label>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Relation between a realizable entity and a process. Reciprocal relation of realizes</efo:definition>
    <rdfs:domain rdf:resource="http://www.ifomis.org/bfo/1.1/snap#SpecificallyDependentContinuant"/>
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/is_realized_by</efo:EFO_URI>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://purl.org/obo/owl/OBO_REL#role_of">
    <rdfs:subPropertyOf rdf:resource="http://purl.org/obo/owl/OBO_REL#inheres_in"/>
    <rdfs:range rdf:resource="http://www.ifomis.org/bfo/1.1/snap#MaterialEntity"/>
    <owl:inverseOf>
      <owl:ObjectProperty rdf:about="http://purl.obolibrary.org/obo/OBI_0000316"/>
    </owl:inverseOf>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >role_of</rdfs:label>
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/is_role_of</efo:EFO_URI>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.obofoundry.org/ro/ro.owl#located_in">
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/located_in</efo:EFO_URI>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >located_in</rdfs:label>
    <owl:inverseOf rdf:resource="http://www.obofoundry.org/ro/ro.owl#location_of"/>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_0001698">
    <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#TransitiveProperty"/>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >has_unit</rdfs:label>
    <rdfs:subPropertyOf>
      <owl:ObjectProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_0000824"/>
    </rdfs:subPropertyOf>
    <owl:inverseOf rdf:resource="http://www.ebi.ac.uk/efo/EFO_0001697"/>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_0000824">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >relationship</rdfs:label>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.obofoundry.org/ro/ro.owl#has_participant">
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    ></efo:definition_citation>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >has_participant</rdfs:label>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Has_participant is a primitive instance-level relation between a process, a continuant, and a time at which the A continuant participates in some way in the process. The relation obtains, for example, when this particular process of oxygen exchange across this particular alveolar membrane has_participant this particular sample of hemoglobin at this particular time.</efo:definition>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://purl.obolibrary.org/obo/OBI_0000316">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >has_role</rdfs:label>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >A relation between a continuant C and a role R. The reciprocal relation of role_of.</efo:definition>
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/has_role</efo:EFO_URI>
    <rdfs:subPropertyOf rdf:resource="http://purl.org/obo/owl/OBO_REL#bearer_of"/>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://purl.obolibrary.org/obo/OBI_0000298">
    <efo:EFO_URI rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >http://www.ebi.ac.uk/efo/has_quality</efo:EFO_URI>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >has_quality</rdfs:label>
    <rdfs:subPropertyOf rdf:resource="http://purl.org/obo/owl/OBO_REL#bearer_of"/>
  </owl:ObjectProperty>
  <owl:ObjectProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_0000742">
    <rdfs:range rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000311"/>
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >is_tumor_of</rdfs:label>
    <rdfs:subPropertyOf rdf:resource="http://www.ebi.ac.uk/efo/EFO_0000824"/>
  </owl:ObjectProperty>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/reason_for_obsolescence"/>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/example_of_usage"/>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/definition_editor"/>
  <obo:OBI_0000245 rdf:about="http://www.ebi.ac.uk/efo/EFO_0002910">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >ENCODE</rdfs:label>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >ENCODE, full name the Encyclopedia Of DNA Elements, is a public research consortium which has the aim of identifying all functional elements in the human genome sequence.</efo:definition>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >ENCODE website &lt;http://www.genome.gov/10005107&gt;</efo:definition_citation>
  </obo:OBI_0000245>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/bioportal_provenance"/>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/primary_source"/>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/creator"/>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/ArrayExpress_label"/>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/source_definition"/>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/alternative_term"/>
  <obo:OBI_0000245 rdf:about="http://www.ebi.ac.uk/efo/EFO_0002911">
    <rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >The International HapMap Project</rdfs:label>
    <efo:definition_citation rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >Tha HapMap Project webpage &lt;http://hapmap.ncbi.nlm.nih.gov&gt;</efo:definition_citation>
    <efo:definition rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >The International HapMap Project is a partnership of scientists and funding agencies from Canada, China, Japan, Nigeria, the United Kingdom and the United States to develop a public resource that will help researchers find genes associated with human disease and response to pharmaceuticals.</efo:definition>
    <efo:definition_editor rdf:datatype="http://www.w3.org/2001/XMLSchema#string"
    >James Malone</efo:definition_editor>
  </obo:OBI_0000245>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/branch_class"/>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/definition"/>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/obsoleted_in_version"/>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/organizational_class"/>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/definition_citation"/>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/description"/>
  <owl:AnnotationProperty rdf:about="http://www.ebi.ac.uk/efo/EFO_URI"/>
</rdf:RDF>

<!-- Created with Protege (with OWL Plugin 3.4.4, Build 579)  http://protege.stanford.edu -->
