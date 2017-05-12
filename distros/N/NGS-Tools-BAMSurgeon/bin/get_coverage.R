chr <- seq(1,22);
chr <- append(chr, 'X');

coverage <- c();

for (i in seq(1,23)) {
	print(paste0("Processing chr",i,".txt..."));
	if (file.exists(paste0('chr',i,'.txt'))) {
		chr.data <- read.delim(paste0('chr',i,'.txt'), header=TRUE, sep='\t');
		coverage[i] <- mean(chr.data$Good_depth);
		}
	else {
		coverage[i] <- NA;
		}
	}

write.table(data.frame(chr,coverage), file='coverage.txt', quote=FALSE, row.names=FALSE, sep='\t');
