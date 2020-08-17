pipeline {
    agent any
    stages {
        stage('Install dependencies') {
            steps {
                sh 'carton install'
            }
        }
        stage('Create Makefile') {
            steps {
                sh 'perl Makefile.PL'
            }
        }
        stage('build') {
            steps {
                sh 'perl -V'
            }
        }
    }
}
