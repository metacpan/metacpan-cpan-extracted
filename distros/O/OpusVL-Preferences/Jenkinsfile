node {
   stage('Preparation') { // for display purposes
      // Get some code from a GitHub repository
	  checkout scm
   }

   stage('Install deps') {
      sh "/opt/perl5/bin/cpanm -M http://cpan.opusvl.com --installdeps ."
   }
   stage('Test') {
      sh "/opt/perl5/bin/prove -I ~/perl5/lib/perl5/ -l t --timer --formatter=TAP::Formatter::JUnit  > ${BUILD_TAG}-junit.xml"
   }
   stage('Results') {
      junit '*junit.xml'
   }

}
