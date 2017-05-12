/*
 * segmentize.c
 *
 *  Created on: 10 aug 2012
 *      Author: Wolftower
 *
 *  Description
 *		This library implements a function that segments
 *      chromosome/substring files into smaller chunks
 */

#include "segmentize.h"

void seq2chunks(char* sequence, char* seqHeader, char* outputDir, const char* nopathFile, int offset, int* chunkIndex){
	int windowSize = 200;
	int stepSize = 20;
	int currentStep = 0;
	int windowsPerChunk = 50000;
	int windowIndex;
	char window[203];
	int breakSwitch = 0;
	int seqLen = strlen(sequence);
	int nucIndex;
	FILE *chunk = NULL;
	for (windowIndex = 0; windowIndex * stepSize < seqLen; windowIndex++) {
		int windowStart = windowIndex * stepSize;
		
		//Create new chunk
		if (windowIndex % windowsPerChunk == 0) {
			*chunkIndex = *chunkIndex + 1;
			char indexBuffer[10];
			char chunkName[100];
			sprintf(indexBuffer, "%d", *chunkIndex);
			strcpy(chunkName, outputDir);
			strcat(chunkName, nopathFile);
			strcat(chunkName, "_chunk");
			strcat(chunkName, indexBuffer);
			strcat(chunkName, ".txt");
			if (chunk != NULL) {
				fclose(chunk);
			}
			if (!(chunk = fopen(chunkName, "wt"))) {
				printf("GenoScan error: Unable to write '%s' chunk\n", chunkName);
				exit(EXIT_FAILURE);
			}
		}
		
		//Reset window
		strcpy(window, "");
		
		//Copy nucleotides from sequence
		int windowStop;
		if (seqLen - windowStart < windowSize){
			windowStop = seqLen - windowStart;
			breakSwitch = 1;
		}
		else {
			windowStop = windowSize;
		}
		for (nucIndex = 0; nucIndex < windowStop; nucIndex++) {
			window[nucIndex] = sequence[windowStart + nucIndex];
		}
		window[nucIndex] = '\n';
		window[nucIndex+1] = '\n';
		window[nucIndex+2] = '\0';
		
		//Create header
		char header[200];
		char nucStart[100];
		char nucEnd[100];
		int headerStart = windowStart + offset;
		int headerEnd = windowStart + offset + nucIndex;
		sprintf(nucStart, "%d", headerStart);
		sprintf(nucEnd, "%d", headerEnd);
		strcpy(header, seqHeader);
		strcat(header, " | pos ");
		strcat(header, nucStart);
		strcat(header, "-");
		strcat(header, nucEnd);
		strcat(header, "\n");
		
		//Write to file
		fwrite(header, sizeof(char), strlen(header), chunk);
		fwrite(window, sizeof(char), strlen(window), chunk);
		
		if (breakSwitch) {
			break;
		}
	}
	fclose(chunk);
}

int segmentize(int* filterFlags, char* manifest, char* outputDir, int VERBOSE) {
	FILE *inputFile;
	int numFiles = 0;
	char line[200];
	char fileArray[100][100];
	
	if (!(inputFile = fopen(manifest, "rt"))) {
		printf("GenoScan error: Input manifest '%s' could not be read\n", manifest);
		exit(EXIT_FAILURE);
	}
	
	//Read input file
	while (fgets(line, sizeof(line), inputFile) != NULL) {
		int len = strlen(line);
		if(line[len-1] == '\n'){
			strncpy(fileArray[numFiles], line, len-1);
			fileArray[numFiles][len-1] = '\0';
		}
		else{
			strcpy(fileArray[numFiles], line);
		}
		numFiles++;
	}
	numFiles = numFiles / 2;
	fclose(inputFile);
	
	//Read sequence files
	int file;
	int fileCounter = -1;
	int seqMemory = 280000000;
	char* sequence = malloc(seqMemory * sizeof(char));
	for (file = 0; file < numFiles * 2; file+=2) {
		fileCounter++;
		char seqfile[100];
		char nopathFile[100];
		strcpy(seqfile, fileArray[file]);
		strcpy(nopathFile, fileArray[file+1]);
		int fileIndex = fileCounter + 1;
		if (VERBOSE) {
			printf("    Segmentizing file %d/%d\r", fileIndex, numFiles);
		}
		fflush(stdout);
		char buffer[200];
		int nucIndex;
		FILE *fp;
		char fileHeader[200];
		
		//Open sequence file
		if (!(fp = fopen(seqfile, "rt"))){
			printf("GenoScan error: Unable to read input sequence file '%s'\n", seqfile);
			exit(EXIT_FAILURE);
		}
		
		//Segmentize chromosome sequence
		int chunkIndex = 0;
		if(!filterFlags[fileCounter]){
			fgets(line, sizeof(line), fp);
			strncpy(fileHeader, line, strlen(line) - 1);
			fileHeader[strlen(line) - 1] = '\0';
			int nucRead = 0;
			while(fgets(line, sizeof(line), fp) != NULL){
				int length = strlen(line);
				strcpy(buffer, line);
				int nucBuffer = 0;
				for (nucIndex = 0; nucIndex < length; nucIndex++) {
					if (buffer[nucIndex] != '\n') {
						sequence[nucRead + nucIndex] = buffer[nucIndex];
						nucBuffer++;
					}
				}
				nucRead += nucBuffer;
			}
			sequence[nucRead] = '\0';
			seq2chunks(sequence, fileHeader, outputDir, nopathFile, 1, &chunkIndex);
		}
		
		//Segmentize substring sequences
		else{
			while(fgets(line, sizeof(line), fp) != NULL){
				strncpy(fileHeader, line, strlen(line) - 1);
				fileHeader[strlen(line) - 1] = '\0';
				int subStart;
				fgets(line, sizeof(line), fp);
				subStart = atoi(line);
				fgets(line, sizeof(line), fp);
				fgets(sequence, seqMemory, fp);
				seq2chunks(sequence, fileHeader, outputDir, nopathFile, subStart, &chunkIndex);
				strcpy(sequence, "");
			}
		}
		fclose(fp);
	}
	
	//Free sequnce memory
	free(sequence);
	
	if(VERBOSE){
		printf("\n");
	}
	return 1;
}

