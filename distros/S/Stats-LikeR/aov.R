yield <- c(5.5, 5.4, 5.8, 4.5, 4.8, 4.2)
ctrl <- c(1,     1,   1,   0,   0,   0)

# Combine them into a named list (the R equivalent of your hash)
my_list <- list(yield = yield, ctrl = ctrl)

# Convert the list into a "long" dataframe
# This creates two columns: "values" and "ind" (the group name)
my_data <- stack(my_list)

# Rename columns for clarity (optional but good practice)
colnames(my_data) <- c("Value", "Group")
anova_model <- aov(Value ~ Group, data = my_data)
result <- summary(anova_model)
# Flatten the result object so we can iterate through everything (coefficients, residuals, etc.)
flat_result <- unlist(result)

for (attr in names(flat_result)) {
  val <- flat_result[[attr]]
  
  # Format to 15 decimals if it's a number, otherwise print as-is
  if (is.numeric(val)) {
    cat(sprintf("%s %.15f\n", attr, val))
  } else {
    cat(sprintf("%s %s\n", attr, val))
  }
}
for (attr in names(result)) {
  cat(sprintf("%s %.15f\n", attr, as.numeric(result[[attr]])))
}
