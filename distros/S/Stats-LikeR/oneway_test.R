yield <- c(5.5, 5.4, 5.8, 4.5, 4.8, 4.2)
ctrl <- c(1,     1,   1,   0,   0,   0)

# Combine them into a named list (the R equivalent of your hash)
my_list <- list(yield = yield, ctrl = ctrl)

# Convert the list into a "long" dataframe
# This creates two columns: "values" and "ind" (the group name)
my_data <- stack(my_list)

# Rename columns for clarity (optional but good practice)
colnames(my_data) <- c("Value", "Group")
anova_model <- oneway.test(Value ~ Group, data = my_data)
for (k in c('statistic','parameter', 'p.value')) {
	cat(sprintf('%s = %.15f', k, anova_model[[k]]), "\n")
}
#---
print('--------')
# Combine them into a standard dataframe (side-by-side columns)
my_data <- data.frame(yield = yield, ctrl = ctrl)
# Tell R that 'ctrl' represents categorical groups (0 and 1), not continuous numbers
my_data$ctrl <- as.factor(my_data$ctrl)
# Run the one-way ANOVA with your requested formula
anova_model <- oneway.test(yield ~ ctrl, data = my_data)
# Print the results
for (k in c('statistic', 'parameter', 'p.value')) {
    cat(sprintf('%s = %.15f', k, anova_model[[k]]), "\n")
}
