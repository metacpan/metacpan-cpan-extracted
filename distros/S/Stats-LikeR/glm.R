data <- data.frame(
  y = c(2.0, 4.0, 6.0),
  x = c(1.0, 2.0, 3.0)
)

# Run the Generalized Linear Model
# The - 1 in the formula removes the intercept
res <- glm(y ~ x - 1, data = data, family = gaussian)
print(res)
# View the results
summary(res)

