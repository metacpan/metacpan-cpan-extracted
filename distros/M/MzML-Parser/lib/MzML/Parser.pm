package MzML::Parser;

use v5.12;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use MzML::Registry;
use MzML::MzML;
use MzML::Cv;
use MzML::CvList;
use MzML::CvParam;
use MzML::SourceFile;
use MzML::SourceFileList;
use MzML::ReferenceableParamGroupList;
use MzML::ReferenceableParamGroup;
use MzML::SampleList;
use MzML::Sample;
use MzML::InstrumentConfigurationList;
use MzML::InstrumentConfiguration;
use MzML::SoftwareList;
use MzML::Software;
use MzML::SoftwareParam;
use MzML::ScanSettingsList;
use MzML::ScanSettings;
use MzML::DataProcessingList;
use MzML::DataProcessing;
use MzML::ProcessingMethod;
use MzML::Run;
use MzML::SourceFileRefList;
use MzML::SpectrumList;
use MzML::Spectrum;
use MzML::ChromatogramList;
use MzML::Chromatogram;
use MzML::Scan;
use MzML::ScanWindowList;
use MzML::ScanWindow;
use MzML::TargetList;
use MzML::Target;
use MzML::SourceFileRef;
use MzML::PrecursorList;
use MzML::Precursor;
use MzML::Activation;
use MzML::IsolationWindow;
use MzML::SelectedIonList;
use MzML::SelectedIon;
use MzML::BinaryDataArrayList;
use MzML::BinaryDataArray;
use XML::Twig;
use URI;

our $VERSION = '0.1';

my $reg = MzML::Registry->new();

sub parse {
    my $self = shift;
    my $file = shift;

    my %data;

    my $parser = XML::Twig->new(
        twig_handlers =>
        {
            mzML                            =>  \&parse_mzml,
            cvList                          =>  \&parse_cvlist,
            fileContent                     =>  \&parse_filecontent,
            sourceFileList                  =>  \&parse_sourcefilelist,
            referenceableParamGroupList     =>  \&parse_refparamgroup,
            sampleList                      =>  \&parse_samplelist,
            instrumentConfigurationList     =>  \&parse_intrconflist,
            softwareList                    =>  \&parse_softwarelist,
            scanSettingsList                =>  \&parse_scansettinglist,
            dataProcessingList              =>  \&parse_dataproclist,
            run                             =>  \&parse_run,
        },
        pretty_print => 'indented',
    );

    $parser->parsefile($file);

    return $reg;
}

sub parse_mzml {
    my ($parser, $node) = @_;

    my $mzml = MzML::MzML->new();

    $mzml->version($node->{'att'}->{'version'});
    $mzml->id($node->{'att'}->{'id'}) if defined ($node->{'att'}->{'id'});
    $mzml->accession($node->{'att'}->{'accession'}) if defined ($node->{'att'}->{'accession'});

    $reg->mzML($mzml);
}

sub parse_cvlist {
    my ($parser, $node) = @_;

    my @cv = $node->children;
    my @list;

    for my $el ( @cv ) {
        
        my $cv = MzML::Cv->new();

        $cv->uri(my $uri = URI->new($el->{'att'}->{'URI'}));
        $cv->fullName($el->{'att'}->{'fullName'});
        $cv->id($el->{'att'}->{'id'});
        $cv->version($el->{'att'}->{'version'}) if defined ($el->{'att'}->{'version'});
        
        push(@list, $cv);
    }

    my $cvlist = MzML::CvList->new();
    
    $cvlist->count($node->{'att'}->{'count'});
    $cvlist->cv(\@list);

    $reg->cvlist($cvlist);
}

sub parse_filecontent {
    my ($parser, $node) = @_;

    my @subnodes = $node->children;
    
    for my $el ( @subnodes ) {

        if ( $el->name eq 'cvParam' ) {
            
            my $cvp = get_cvParam($el);
            $reg->fileDescription->fileContent->cvParam($cvp);

        } elsif ( $el->name eq 'referenceableParamGroupRef' ) {

            my $ref = get_referenceableParamGroupRef($el);
            $reg->fileContent->referenceableParamGroupRef($ref);

        } elsif ($el->name eq 'userParam' ) {
            
            my $user = get_userParam($el);
            $reg->fileDescription->fileContent->userParam($user);

        }

    }
}

sub parse_sourcefilelist {
    my ($parser, $node) = @_;
    
    my @subnodes = $node->children;
    my @list;

    for my $el ( @subnodes ) {
        
        my $sf = MzML::SourceFile->new();

        $sf->id($el->{'att'}->{'id'});
        $sf->name($el->{'att'}->{'name'});
        $sf->location($el->{'att'}->{'location'});

        my @undernodes = $el->children;
        
        my @cvparam_list;
        my @reference_list;
        my @user_list;
        
        for my $subel ( @undernodes ) {

            if ( $subel->name eq 'cvParam' ) {
		    
    		    my $cvp = get_cvParam($subel);
                push(@cvparam_list, $cvp);

    		} elsif ( $subel->name eq 'referenceableParamGroupRef' ) {

    		    my $ref = get_referenceableParamGroupRef($subel);
    		    push(@reference_list, $ref);

    		} elsif ($subel->name eq 'userParam' ) {
		    
    		    my $user = get_userParam($subel);
    		    push(@user_list, $user);

	    	}

        }

        $sf->cvParam(\@cvparam_list);
        $sf->referenceableParamGroupRef(\@reference_list);
        $sf->userParam(\@user_list);

        push(@list, $sf);
    }

    my $slist = MzML::SourceFileList->new();

    $slist->count($node->{'att'}->{'count'});
    $slist->sourceFile(\@list);

    $reg->fileDescription->sourceFileList($slist);

}

sub parse_refparamgroup {
    my ($parser, $node) = @_;

    my @subnodes = $node->children;
    my @list;

    for my $el ( @subnodes ) {
        
        my $refgl = MzML::ReferenceableParamGroup->new();

        $refgl->id($el->{'att'}->{'id'});

        my @undernodes = $el->children;

        my @cvparam_list;
        my @user_list;

        for my $subel ( @undernodes ) {

            if ( $subel->name eq 'cvParam' ) {
		    
    		    my $cvp = get_cvParam($subel);
                push(@cvparam_list, $cvp);

    		} elsif ($subel->name eq 'userParam' ) {
		    
    		    my $user = get_userParam($subel);
                push(@user_list, $user);

	    	}

        }
        
        $refgl->cvParam(\@cvparam_list);
        $refgl->userParam(\@user_list);
        push(@list, $refgl);                                       

    }

    my $refg = MzML::ReferenceableParamGroupList->new();

    $refg->count($node->{'att'}->{'count'});
    $refg->referenceableParamGroup(\@list);

    $reg->referenceableParamGroupList($refg);

}

sub parse_samplelist {
    my ($parser, $node) = @_;

    my @subnodes = $node->children;
    my @list;

    for my $el ( @subnodes ) {

        my $sample = MzML::Sample->new();

        $sample->id($el->{'att'}->{'id'});
        $sample->name($el->{'att'}->{'name'}) if defined($el->{'att'}->{'name'});

        my @undernodes = $el->children;
        
        my @cvparam_list;
        my @reference_list;
        my @user_list;

    	for my $subel ( @undernodes ) {

    	    if ( $subel->name eq 'cvParam' ) {

                my $cvp = get_cvParam($subel);
    		    push(@cvparam_list, $cvp);

    		} elsif ( $subel->name eq 'referenceableParamGroupRef' ) {

    		    my $ref = get_referenceableParamGroupRef($subel);
    		    push(@reference_list, $ref);

    		} elsif ($subel->name eq 'userParam' ) {
		    
    		    my $user = get_userParam($subel);
    		    push(@user_list, $user);
    
    	    }

        }

        $sample->cvParam(\@cvparam_list);
        $sample->referenceableParamGroupRef(\@reference_list);
        $sample->userParam(\@user_list);

        push(@list, $sample);
        
    }

    my $sampl = MzML::SampleList->new();

    $sampl->count($node->{'att'}->{'count'});
    $sampl->sample(\@list);

    $reg->sampleList($sampl);

}

sub parse_intrconflist {
    my ($parser, $node) = @_;

    my @subnodes_1 = $node->children;
    my @list;
    my @clist;

    for my $el ( @subnodes_1 ) {
        
        my $ic = MzML::InstrumentConfiguration->new();
        $ic->id($el->{'att'}->{'id'});
        
        my @subnodes_2 = $el->children;

        my $clist;

        my @reference_list;

        my $source;
        my $analyzer;
        my $detector;

        for my $el2 ( @subnodes_2 ) {

    		if ( $el2->name eq 'referenceableParamGroupRef' ) {

    		    my $ref = get_referenceableParamGroupRef($el2);
    		    push(@reference_list, $ref);

    		} elsif ( $el2->name eq 'componentList' ) {

                undef($source);
                undef($analyzer);
                undef($detector);

                $clist = MzML::ComponentList->new();
                $clist->count($el2->{'att'}->{'count'});

                my @subnodes_3 = $el2->children;

                my (@source_cvparam_list, @analyzer_cvparam_list, @detector_cvparam_list);
                my (@source_reference_list, @analyzer_reference_list, @detector_reference_list);
                my (@source_user_list, @analyzer_user_list, @detector_user_list);

                for my $el3 ( @subnodes_3 ) {
                    
                    if ( $el3->name eq 'source' ) {
                        
                        $source = MzML::Source->new();
                        $source->order($el3->{'att'}->{'order'});

                        my @subnodes_4 = $el3->children;

                        for my $el4 ( @subnodes_4 ) {

                            if ( $el4->name eq 'cvParam' ) {

                                my $cvp = get_cvParam($el4);
                                push(@source_cvparam_list, $cvp);

                            } elsif ( $el4->name eq 'referenceableParamGroupRef' ) {

                                my $ref = get_referenceableParamGroupRef($el4);
                                push(@source_reference_list, $ref);

                            } elsif ($el4->name eq 'userParam' ) {

                                my $user = get_userParam($el4);
                                push(@source_user_list, $user);
                                
                            }
                        }
                        
                    } elsif ( $el3->name eq 'analyzer' ) {

                        $analyzer = MzML::Analyzer->new();
                        $analyzer->order($el3->{'att'}->{'order'});

                        my @subnodes_4 = $el3->children;

                        for my $el4 ( @subnodes_4 ) {

                            if ( $el4->name eq 'cvParam' ) {

                                my $cvp = get_cvParam($el4);
                                push(@analyzer_cvparam_list, $cvp);

                            } elsif ( $el4->name eq 'referenceableParamGroupRef' ) {

                                my $ref = get_referenceableParamGroupRef($el4);
                                push(@analyzer_reference_list, $ref);

                            } elsif ($el4->name eq 'userParam' ) {

                                my $user = get_userParam($el4);
                                push(@analyzer_user_list, $user);
                                
                            }
                        }

                    } elsif ( $el3->name eq 'detector' ) {

                        $detector = MzML::Detector->new();
                        $detector->order($el3->{'att'}->{'order'});

                        my @subnodes_4 = $el3->children;

                        for my $el4 ( @subnodes_4 ) {

                            if ( $el4->name eq 'cvParam' ) {

                                my $cvp = get_cvParam($el4);
                                push(@detector_cvparam_list, $cvp);

                            } elsif ( $el4->name eq 'referenceableParamGroupRef' ) {

                                my $ref = get_referenceableParamGroupRef($el4);
                                push(@detector_reference_list, $ref);

                            } elsif ($el4->name eq 'userParam' ) {

                                my $user = get_userParam($el4);
                                push(@detector_user_list, $user);
                                
                            }
                        }

                    }

                }#end el3

                $source->cvParam(\@source_cvparam_list);
                $source->userParam(\@source_user_list);
                $source->referenceableParamGroupRef(\@source_reference_list);

                $analyzer->cvParam(\@analyzer_cvparam_list);
                $analyzer->userParam(\@analyzer_user_list);
                $analyzer->referenceableParamGroupRef(\@analyzer_reference_list);

                $detector->cvParam(\@detector_cvparam_list);
                $detector->userParam(\@detector_user_list);
                $detector->referenceableParamGroupRef(\@detector_reference_list);

                $clist->source($source);
                $clist->analyzer($analyzer);
                $clist->detector($detector);

                push(@clist, $clist);

                $ic->componentList($clist);

            } elsif ( $el2->name eq 'softwareRef' ) {
                
                my $software = MzML::SoftwareRef->new();
                $software->ref($el2->{'att'}->{'ref'});
                
                $ic->softwareRef($software);

            }

        }# end el2

        push(@list, $ic);

    }# end el

    my $icl = MzML::InstrumentConfigurationList->new();
    $icl->count($node->{'att'}->{'count'});
    $icl->instrumentConfiguration(\@list);

    $reg->instrumentConfigurationList($icl);
}

sub parse_softwarelist {
    my ($parser, $node) = @_;

    my @subnodes_1 = $node->children;
    my @list;

    my $sw;
    my $sp;

    for my $el1 ( @subnodes_1 ) {

        if ( $el1->name eq 'software' ) {
            
            $sw = MzML::Software->new();
            
            $sw->id($el1->{'att'}->{'id'}) if defined ($el1->{'att'}->{'id'});
            $sw->version($el1->{'att'}->{'version'}) if defined ($el1->{'att'}->{'version'});
            
            my @subnodes_2 = $el1->children;
            
            my @cvparam;
            my @reference;
            my @userlist;

            for my $el2 ( @subnodes_2 ) {

                if ( $el2->name eq 'cvParam' ) {
        
                    my $cvp = get_cvParam($el2);
                    push(@cvparam, $cvp);

                } elsif ( $el2->name eq 'referenceableParamGroupRef' ) {

                    my $ref = get_referenceableParamGroupRef($el2);
                    push(@reference, $ref);

                } elsif ( $el2->name eq 'userParam' ) {

                    my $user = get_userParam($el2);
                    push(@userlist, $user);

                }

            }#end el2

            $sw->cvParam(\@cvparam);
            $sw->referenceableParamGroupRef(\@reference);
            $sw->userParam(\@userlist);

        }

        push(@list, $sw);
        
    }#end el1

    my $swl = MzML::SoftwareList->new();
    $swl->count($node->{'att'}->{'count'});
    $swl->software(\@list);

    $reg->softwareList($swl);

}

sub parse_scansettinglist {
    my ($parser, $node) = @_;

    my $scanSettingsList = MzML::ScanSettingsList->new();

    if ( $node->name eq 'scanSettingsList' ) {
        
        $scanSettingsList->count($node->{'att'}->{'count'});
    }

    my @subnodes_1 = $node->children;

    my $scanSettings;
    my @scansettingslist;

    for my $el1 ( @subnodes_1 ) {

        if ( $el1->name eq 'scanSettings' ) {
            #inside scansettings
            
            $scanSettings = MzML::ScanSettings->new();

            $scanSettings->id($el1->{'att'}->{'id'});

            my @subnodes_2 = $el1->children;

            my @cvparam_el2;
            my @reference_el2;
            my @user_el2;

            my $sourceFileRefList;
            my $sourceFileRef;
            my @sourcefilelist;

            my $targetList;
            my $target;
            my @targetlist;

            for my $el2 ( @subnodes_2 ) {
                #inside scansettings tag

                if ( $el2->name eq 'cvParam' ) {

            	    my $cvp = get_cvParam($el2);
        	        push(@cvparam_el2, $cvp);
    
                } elsif ( $el2->name eq 'referenceableParamGroupRef' ) {

                	my $ref = get_referenceableParamGroupRef($el2);
                	push(@reference_el2, $ref);

                } elsif ( $el2->name eq 'userParam' ) {

                	my $user = get_userParam($el2);
                	push(@user_el2, $user);

                } elsif ( $el2->name eq 'sourceFileRefList' ) {

                    $sourceFileRefList = MzML::SourceFileRefList->new();

                    my $el3 = $el2->first_child;
                    
                    $sourceFileRef = MzML::SourceFileRef->new();
                    $sourceFileRef->ref($el3->{'att'}->{'ref'});

                    push(@sourcefilelist, $sourceFileRef);

                } elsif ( $el2->name eq 'targetList' ) {

                    $targetList = MzML::TargetList->new();
                    $targetList->count($el2->{'att'}->{'count'});

                    my @subnodes_3 = $el2->children;

                    for my $el3 ( @subnodes_3 ) {
                        #inside targetlist tag
                        
                        $target = MzML::Target->new();

                        my @cvparam_el4;
                        my @reference_el4;
                        my @user_el4;

                        my @subnodes_4 = $el3->children;

                        for my $el4 ( @subnodes_4 ) {
                            #inside target tag
                            
                            if ( $el4->name eq 'cvParam' ) {

                        	    my $cvp = get_cvParam($el4);
                    	        push(@cvparam_el4, $cvp);
    
                            } elsif ( $el4->name eq 'referenceableParamGroupRef' ) {

                            	my $ref = get_referenceableParamGroupRef($el4);
                            	push(@reference_el4, $ref);

                            } elsif ( $el4->name eq 'userParam' ) {

                            	my $user = get_userParam($el4);
                            	push(@user_el4, $user);

                            }

                        }#end el4

                        $target->cvParam(\@cvparam_el4);
                        $target->referenceableParamGroupRef(\@reference_el4);
                        $target->userParam(\@user_el4);

                        push(@targetlist, $target);
                        
                        
                    }#end el3

                }

            }#end el2

            $targetList->target(\@targetlist);
            
            $sourceFileRefList->sourceFileRef(\@sourcefilelist);

            $scanSettings->targetList($targetList);
            $scanSettings->sourceFileRefList($sourceFileRefList);
            $scanSettings->cvParam(\@cvparam_el2);
            $scanSettings->referenceableParamGroupRef(\@reference_el2);
            $scanSettings->userParam(\@user_el2);

            push(@scansettingslist, $scanSettings);

        }#end el1
        
    }

    $scanSettingsList->scanSettings(\@scansettingslist);

    $reg->scanSettingsList($scanSettingsList);
}

sub parse_dataproclist {
    my ($parser, $node) = @_;

    my @subnodes_1 = $node->children;
    
    my @list;
    my @dataplist;

    my $datap;
    my $proc;

    for my $el1 ( @subnodes_1 ) {

        $datap = MzML::DataProcessing->new();
        $datap->id($el1->{'att'}->{'id'});

        my @subnodes_2 = $el1->children;

        for my $el2 ( @subnodes_2 ) {

            if ( $el2->name eq 'processingMethod' ) {
                
                $proc = MzML::ProcessingMethod->new();
                $proc->order($el2->{'att'}->{'order'});

                my @subnodes_3 = $el2->children;

                my @cvparam_list;
                my @reference_list;
                my @user_list;

                for my $el3 ( @subnodes_3 ) {

                    if ( $el3->name eq 'cvParam' ) {

                        my $cvp = get_cvParam($el3);
                        push(@cvparam_list, $cvp);

                    } elsif ( $el3->name eq 'referenceableParamGroupRef' ) {

                        my $ref = get_referenceableParamGroupRef($el3);
                        push(@reference_list, $ref);

                    } elsif ( $el3->name eq 'userParam' ) {

                        my $user = get_userParam($el3);
                        push(@user_list, $user);

                    }

                }#end el3

                $proc->cvParam(\@cvparam_list);
                $proc->userParam(\@user_list);
                $proc->referenceableParamGroupRef(\@reference_list);

                push(@dataplist, $proc);

            }

        }#end el2

        $datap->processingMethod(\@dataplist);
        push(@list, $datap);
        
    }#end el1
    
    my $dpl = MzML::DataProcessingList->new();
    $dpl->count($node->{'att'}->{'count'});
    $dpl->dataProcessing(\@list);

    $reg->dataProcessingList($dpl);

}

sub parse_run {
    my ($parser, $node) = @_;

    my $run = MzML::Run->new();
    $run->defaultInstrumentConfigurationRef($node->{'att'}->{'defaultInstrumentConfigurationRef'});
    $run->id($node->{'att'}->{'id'});
    $run->sampleRef($node->{'att'}->{'sampleRef'}) if defined $node->{'att'}->{'sampleRef'};
    $run->startTimeStamp($node->{'att'}->{'startTimeStamp'}) if defined $node->{'att'}->{'startTimeStamp'};

    my @subnodes_1 = $node->children;
    
    my @cvparam_list;
    my @reference_list;
    my @user_list;                                            

    my $sfrl;
    my $sl;
    my $cl;

    for my $el1 ( @subnodes_1 ) {
        
        if ( $el1->name eq 'sourceFileRefList' ) {
            
            #$sfrl = MzML::SourceFileRefList->new();
            #TODO not implemented

        } elsif ( $el1->name eq 'spectrumList' ) {

            $sl = MzML::SpectrumList->new();

            $sl->count($el1->{'att'}->{'count'});
            $sl->defaultDataProcessingRef($el1->{'att'}->{'defaultDataProcessingRef'});

            my @subnodes_2 = $el1->children;
            my @spectrum;

            for my $el2 ( @subnodes_2 ) {
                #inside spectrumlist tag


				$cl = MzML::ChromatogramList->new();


                if ( $el2->name eq 'spectrum' ) {

                    my $spec = MzML::Spectrum->new();

                    $spec->dataProcessingRef($el2->{'att'}->{'dataProcessingRef'}) if defined $el2->{'att'}->{'dataProcessingRef'};
                    $spec->defaultArrayLength($el2->{'att'}->{'defaultArrayLength'});
                    $spec->id($el2->{'att'}->{'defaultArrayLength'});
                    $spec->index($el2->{'att'}->{'index'});
                    $spec->nativeID($el2->{'att'}->{'nativeID'}) if defined $el2->{'att'}->{'nativeID'};;
                    $spec->sourceFileRef($el2->{'att'}->{'sourceFileRef'}) if defined $el2->{'att'}->{'sourceFileRef'};
                    $spec->spotID($el2->{'att'}->{'spotID'}) if defined $el2->{'att'}->{'spotID'};

                    my @subnodes_3 = $el2->children;               
                    my @cvparam;

                    my @cvparam_el3;
                    my @reference_el3;
                    my @user_el3;

                    my $binaryDataArrayList;
                    my $binaryDataArray;
                    my @binarylist;

                    for my $el3 ( @subnodes_3 ) {
                    #inside spectrum tag

                        if ( $el3->name eq 'cvParam' ) {

                            my $cvp = get_cvParam($el3);
                            push(@cvparam_el3, $cvp);

                        } elsif ( $el3->name eq 'referenceableParamGroupRef' ) {

                            my $ref = get_referenceableParamGroupRef($el3);
                            push(@reference_el3, $ref);

                        } elsif ( $el3->name eq 'userParam' ) {

                            my $user = get_userParam($el3);
                            push(@user_el3, $user);

                        } elsif ( $el3->name eq 'scanList' ) {

                            my @subnodes_4 = $el3->children;

                            my @cvparam;
                            my @reference;
                            my @user;

                            my $scanlist;
                            my @scans;

                            for my $el4 ( @subnodes_4 ) {
                                #inside scanlist tag

                                $scanlist = MzML::ScanList->new();

                                if ( $el4->name eq 'cvParam' ) {

                                    my $cvp = get_cvParam($el4);
                                    push(@cvparam, $cvp);

                                } elsif ( $el4->name eq 'referenceableParamGroupRef' ) {

                                    my $ref = get_referenceableParamGroupRef($el4);
                                    push(@reference, $ref);

                                } elsif ( $el4->name eq 'userParam' ) {

                                    my $user = get_userParam($el4);
                                    push(@user, $user);

                                } elsif ( $el4->name eq 'scan' ) {
                                    
                                    my $scan = MzML::Scan->new();
                                    my @subnodes_5 = $el4->children;

                                    my @cvparam;
                                    my @reference;
                                    my @user;

                                    my $swl;
                                    my @scanwindows;

                                    for my $el5 ( @subnodes_5 ) {
                                        #inside scan tag
										
										$swl = MzML::ScanWindowList->new();
                                      
                                        if ( $el5->name eq 'cvParam' ) {

                                            my $cvp = get_cvParam($el5);
                                            push(@cvparam, $cvp);

                                        } elsif ( $el5->name eq 'referenceableParamGroupRef' ) {
    
                                            my $ref = get_referenceableParamGroupRef($el5);
                                            push(@reference, $ref);

                                        } elsif ( $el5->name eq 'userParam' ) {

                                            my $user = get_userParam($el5);
                                            push(@user, $user);

                                        } elsif ( $el5->name eq 'scanWindowList' ) {

                                            $swl->count($el5->{'att'}->{'count'});

                                        }
                                        
                                        
                                   }#end el5
                                   
                                   $scan->cvParam(\@cvparam);
                                   $scan->referenceableParamGroupRef(\@reference);
                                   $scan->userParam(\@user);
                                   $scan->scanWindowList($swl);                                   

                                   push(@scans, $scan);

                                }
                            
                            }#end el4

                            $scanlist->cvParam(\@cvparam);
                            $scanlist->referenceableParamGroupRef(\@reference);
                            $scanlist->userParam(\@user);
                            $scanlist->scan(\@scans);

                            $spec->scanList($scanlist);

                        } elsif ( $el3->name eq 'precursorList' ) {

                            my $precursorlist = MzML::PrecursorList->new();
                            $precursorlist->count($el3->{'att'}->{'count'});

                            my @subnodes_4 = $el3->children;

                            my $precursor;
                            my @precursorlist;

                            for my $el4 ( @subnodes_4 ) {
                                #inside precursorlist tag

								$precursor = MzML::Precursor->new();

                                if ( $el4->name eq 'precursor' ) {

                                    $precursor->spectrumRef($el4->{'att'}->{'spectrumRef'}) if defined $el4->{'att'}->{'spectrumRef'};

                                    my @subnodes_5 = $el4->children;

                                    my $activation;
                                    my $isolation;
                                    my $selectedIonList;
                                    my $selectedIon;
                                    my @ionlist;

                                    for my $el5 ( @subnodes_5 ) {
                                        #inside precursor tag
                                       
                                        my (@activation_cvparam, @isolation_cvparam);
                                        my (@activation_reference, @isolation_reference);
                                        my (@activation_user, @isolation_user);


										$isolation = MzML::IsolationWindow->new();

                                        
                                        if ( $el5->name eq 'activation' ) {

                                            $activation = MzML::Activation->new();

                                            my @subnodes_6 = $el5->children;

                                            for my $el6 ( @subnodes_6 ) {
                                                #inside activation tag
                                               
                                                if ( $el6->name eq 'cvParam' ) {
    
                                                    my $cvp = get_cvParam($el6);
                                                    push(@activation_cvparam, $cvp);
    
                                                } elsif ( $el6->name eq 'referenceableParamGroupRef' ) {
    
                                                    my $ref = get_referenceableParamGroupRef($el6);
                                                    push(@activation_reference, $ref);
            
                                                 } elsif ( $el6->name eq 'userParam' ) {
        
                                                    my $user = get_userParam($el6);
                                                    push(@activation_user, $user);
        
                                                 }
                                                
                                            }#end el6

                                            $activation->cvParam(\@activation_cvparam);
                                            $activation->referenceableParamGroupRef(\@activation_reference);
                                            $activation->userParam(\@activation_user);

                                        } elsif ( $el5->name eq 'isolationWindow' ) {

                                            my @subnodes_6 = $el5->children;

                                            for my $el6 ( @subnodes_6 ) {
                                                #inside activation tag
                                               
                                                if ( $el6->name eq 'cvParam' ) {
    
                                                    my $cvp = get_cvParam($el6);
                                                    push(@activation_cvparam, $cvp);
    
                                                } elsif ( $el6->name eq 'referenceableParamGroupRef' ) {
    
                                                    my $ref = get_referenceableParamGroupRef($el6);
                                                    push(@activation_reference, $ref);
            
                                                 } elsif ( $el6->name eq 'userParam' ) {
        
                                                    my $user = get_userParam($el6);
                                                    push(@activation_user, $user);
        
                                                 }
                                                
                                            }#end el6

                                            $isolation->cvParam(\@activation_cvparam);
                                            $isolation->referenceableParamGroupRef(\@activation_reference);
                                            $isolation->userParam(\@activation_user);

                                        } elsif ( $el5->name eq 'selectedIonList' ) {

                                            $selectedIonList = MzML::SelectedIonList->new();
                                            $selectedIonList->count($el5->{'att'}->{'count'});
                                            
                                            my @subnodes_6 = $el5->children;
                                            
                                            for my $el6 ( @subnodes_6 ) {
                                                #inside selectedionlist tag

                                                if ( $el6->name eq 'selectedIon' ) {

                                                    $selectedIon = MzML::SelectedIon->new();
                                                    
                                                    my @subnodes_7 = $el6->children;

                                                    my @cvparam_el7;
                                                    my @reference_el7;
                                                    my @user_el7;

                                                    for my $el7 ( @subnodes_7 ) {
                                                        #inside selectedIon tag

                                                        if ( $el7->name eq 'cvParam' ) {
    
                                                            my $cvp = get_cvParam($el7);
                                                            push(@cvparam_el7, $cvp);
    
                                                        } elsif ( $el7->name eq 'referenceableParamGroupRef' ) {
    
                                                            my $ref = get_referenceableParamGroupRef($el7);
                                                            push(@reference_el7, $ref);
            
                                                         } elsif ( $el7->name eq 'userParam' ) {
        
                                                            my $user = get_userParam($el7);
                                                            push(@user_el7, $user);
            
                                                         }

                                                    }#end el7

                                                    $selectedIon->cvParam(\@cvparam_el7);
                                                    
                                                }

                                                push(@ionlist, $selectedIon);

                                            }#end el6

                                            $selectedIonList->selectedIon(\@ionlist);

                                        }

                                    }#end el5


                                    $precursor->activation($activation);
                                    $precursor->isolationWindow($isolation);
                                    $precursor->selectedIonList($selectedIonList);

                                    push(@precursorlist, $precursor);
                                }
                                
                            }#end el4

                            $precursorlist->precursor(\@precursorlist);

                            $spec->precursorList($precursorlist);
                            

                        } elsif ( $el3->name eq 'productList' ) {

                            #TODO : no example provided to create this parsing

                        } elsif ( $el3->name eq 'binaryDataArrayList' ) {

                            $binaryDataArrayList = MzML::BinaryDataArrayList->new();
                            $binaryDataArrayList->count($el3->{'att'}->{'count'});

                            my @subnodes_4 = $el3->children;

                            for my $el4 ( @subnodes_4 ) {
                                #inside binarydataarraylist
                                
                                if ( $el4->name eq 'binaryDataArray' ) {

                                    $binaryDataArray = MzML::BinaryDataArray->new();
                                    $binaryDataArray->encodedLength($el4->{'att'}->{'encodedLength'});

                                    my @subnodes_5 = $el4->children;

                                    my @cvparam_el5;
                                    my @reference_el5;
                                    my @user_el5;

                                    for my $el5 ( @subnodes_5 ) {
                                        #inside binaryDataArray
                                    
                                        if ( $el5->name eq 'cvParam' ) {

        		                            my $cvp = get_cvParam($el5);
        		                            push(@cvparam_el5, $cvp);

        		                        } elsif ( $el5->name eq 'referenceableParamGroupRef' ) {

        		                            my $ref = get_referenceableParamGroupRef($el5);
        		                            push(@reference_el5, $ref);

        		                         } elsif ( $el5->name eq 'userParam' ) {

        		                            my $user = get_userParam($el5);
        		                            push(@user_el5, $user);
        
        		                         } elsif ( $el5->name eq 'binary' ) {
                                             
                                             $binaryDataArray->binary($el5->text);
                                         }

                                    }#end el5

                                    $binaryDataArray->cvParam(\@cvparam_el5);

                                    push(@binarylist, $binaryDataArray);
                                }
    
                            }#end el4

                            $binaryDataArrayList->binaryDataArray(\@binarylist);
                            $spec->binaryDataArrayList($binaryDataArrayList);

                        }


                    }#end el3

                    $spec->cvParam(\@cvparam_el3);
                    $spec->referenceableParamGroupRef(\@reference_el3);
                    $spec->userParam(\@user_el3);

                    push(@spectrum, $spec);

                }

                $sl->spectrum(\@spectrum);

            }#end el2


        } elsif ( $el1->name eq 'chromatogramList' ) {
            
            #$cl = MzML::ChromatogramList->new();
			$cl->count($el1->{'att'}->{'count'});
			$cl->defaultDataProcessingRef($el1->{'att'}->{'defaultDataProcessingRef'});
            
			my @subnodes_2 = $el1->children;

			my @chromatogramlist;
			my $chromatogram;

			for my $el2 ( @subnodes_2 ) {
			#inside chromatogramlist tag
			
				if ( $el2->name eq 'chromatogram' ) {
				
					$chromatogram = MzML::Chromatogram->new();

					$chromatogram->defaultArrayLength($el2->{'att'}->{'defaultArrayLength'}) if defined ($el2->{'att'}->{'defaultArrayLength'});
					$chromatogram->id($el2->{'att'}->{'id'}) if defined ($el2->{'att'}->{'id'});
					$chromatogram->index($el2->{'att'}->{'index'}) if defined ($el2->{'att'}->{'index'});

					my @subnodes_3 = $el2->children;

					my @cvparam_el3;
					my @reference_el3;
					my @user_el3;
					
					my $binaryDataArrayList;
					my $binaryDataArray;
					my @binarydata;
					
					for my $el3 ( @subnodes_3 ) {
						#inside chromatogram tag

						if ( $el3->name eq 'cvParam' ) {

							my $cvp = get_cvParam($el3);
	                        push(@cvparam_el3, $cvp);

	                    } elsif ( $el3->name eq 'referenceableParamGroupRef' ) {

	                    	my $ref = get_referenceableParamGroupRef($el3);
	                        push(@reference_el3, $ref);

	                    } elsif ( $el3->name eq 'userParam' ) {
		
	        	            my $user = get_userParam($el3);
	                        push(@user_el3, $user);

	                    } elsif ( $el3->name eq 'binaryDataArrayList' ) {

							$binaryDataArrayList = MzML::BinaryDataArrayList->new();
							$binaryDataArrayList->count($el3->{'att'}->{'count'});

							my @subnodes_4 = $el3->children;

							for my $el4 ( @subnodes_4 ) {
								#inside binarydataarraylist tag

								if ( $el4->name eq 'binaryDataArray' ) {

									$binaryDataArray = MzML::BinaryDataArray->new();
									$binaryDataArray->encodedLength($el4->{'att'}->{'encodedLength'}) if defined ($el4->{'att'}->{'encodedLength'});
									push(@binarydata, $binaryDataArray);

									my @subnodes_5 = $el4->children;

                                    my @cvparam_el5;
                                    my @reference_el5;
                                    my @user_el5;

									for my $el5 ( @subnodes_5 ) {
                                        #inside binarydataarray

										if ( $el5->name eq 'cvParam' ) {

											my $cvp = get_cvParam($el5);
                                            push (@cvparam_el5, $cvp);

									    } elsif ( $el5->name eq 'referenceableParamGroupRef' ) {

									    	my $ref = get_referenceableParamGroupRef($el5);
										    push(@reference_el5, $ref);

									    } elsif ( $el5->name eq 'userParam' ) {
		
										    my $user = get_userParam($el5);
										    push(@user_el5, $user);

									    } elsif ( $el5->name eq 'binary' ) {

                                            $binaryDataArray->binary($el5->text);

                                        }

									}#end el5

                                    $binaryDataArray->cvParam(\@cvparam_el5);

								}


							}#el4 end

							$binaryDataArrayList->binaryDataArray(\@binarydata);

						}

					}#end el3

					$chromatogram->cvParam(\@cvparam_el3);
					$chromatogram->referenceableParamGroupRef(\@reference_el3);
					$chromatogram->userParam(\@user_el3);
					$chromatogram->binaryDataArrayList($binaryDataArrayList);

					push(@chromatogramlist, $chromatogram);

				}

			}#end el2

			$cl->chromatogram(\@chromatogramlist);

        }

    }#end el1
    

    #$run->sourceFileRefList($sfrl);
    $run->spectrumList($sl);
    $run->chromatogramList($cl);

    $reg->run($run);
}

sub get_cvParam {
    my $el = shift;

    my $cvp = MzML::CvParam->new();
    
    $cvp->accession($el->{'att'}->{'accession'});
    $cvp->cvRef($el->{'att'}->{'cvRef'});
    $cvp->name($el->{'att'}->{'name'});
    $cvp->unitAccession($el->{'att'}->{'unitAccession'}) if defined ($el->{'att'}->{'unitAccession'});
    $cvp->unitName($el->{'att'}->{'unitName'}) if defined ($el->{'att'}->{'unitName'});
    $cvp->value($el->{'att'}->{'value'}) if defined ($el->{'att'}->{'value'});

    return $cvp;
}

sub get_referenceableParamGroupRef {
    my $el = shift;

    my $ref = MzML::ReferenceableParamGroupRef->new();
    $ref->ref($el->{'att'}->{'ref'});
 
    return $ref;
}


sub get_userParam {
    my $el = shift;

    my $user = MzML::UserParam->new();

    $user->name($el->{'att'}->{'name'});
    $user->type($el->{'att'}->{'type'}) if defined ($el->{'att'}->{'type'});
    $user->unitAccession($el->{'att'}->{'unitAccession'}) if defined ($el->{'att'}->{'unitAccession'});
    $user->unitCvRef($el->{'att'}->{'unitCvRef'}) if defined ($el->{'att'}->{'unitCvRef'});
    $user->unitName($el->{'att'}->{'unitName'}) if defined ($el->{'att'}->{'unitName'});
    $user->value($el->{'att'}->{'value'}) if defined ($el->{'att'}->{'value'});

    return $user;
}

1;
