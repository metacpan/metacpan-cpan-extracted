# Load library
library("pheatmap")
#library("heatmaply") # could not install

# Read in the input file as a matrix
data <- as.matrix(read.table("matrix.txt", header = TRUE, row.names = 1))

# Save image
png(filename = "heatmap.png", width = 1000, height = 1000,
    units = "px", pointsize = 12, bg = "white", res = NA)

# Create the heatmap with row and column labels
#heatmap(data, Rowv = FALSE, Colv = FALSE, labRow = rownames(data), labCol = colnames(data))
pheatmap(data)
#heatmaply(data)
#dev.off()
