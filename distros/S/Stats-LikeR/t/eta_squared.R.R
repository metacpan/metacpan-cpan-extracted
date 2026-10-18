# Regenerates the frozen tables in t/eta_squared.R.t.
#   Rscript t/eta_squared.R.R > /tmp/eta.txt
# then paste each section over the one of the same name in the test.  The test
# never runs this; it reads the literals that were pasted from it.
#
# Written against R 4.6.1 (2026-06-24).  The data are R's own, from the
# datasets package, each the subject of a documented one-way example:
#
#   airquality    Ozone ~ Month          ?kruskal.test (Month is numeric, 5:9;
#                                        Ozone has 37 NA)
#   PlantGrowth   weight ~ group         ?PlantGrowth, anova(lm(weight ~ group))
#   InsectSprays  count ~ spray          ?InsectSprays, aov(count ~ spray)
#   chickwts      weight ~ feed          ?chickwts, anova(lm(weight ~ feed))
#
# and warpbreaks, breaks ~ wool + tension (?warpbreaks), for a two-factor
# table.  R has no eta_squared(); the expected values are the sums of squares
# of summary(aov(y ~ factor(g))) put through the definitions in README.md:
#
#   eta_sq   = SS_effect / (SS_effect + SS_resid)
#   omega_sq = (SS_effect - Df_effect * MS_resid) / (SS_effect + SS_resid + MS_resid)
#
# and partial_eta_sq, which for one effect term equals eta_sq.
options(digits = 17, scipen = 500)

num <- function(v) paste(ifelse(is.na(v), "undef", sprintf("%.17g", v)), collapse = ", ")
str <- function(v) paste0("'", v, "'", collapse = ", ")

sets <- list(
    airquality   = list(y = airquality$Ozone,    g = airquality$Month),
    PlantGrowth  = list(y = PlantGrowth$weight,  g = as.character(PlantGrowth$group)),
    InsectSprays = list(y = InsectSprays$count,  g = as.character(InsectSprays$spray)),
    chickwts     = list(y = chickwts$weight,     g = as.character(chickwts$feed))
)

cat("== %DATA\n")
for (s in names(sets)) {
    d <- sets[[s]]
    cat(sprintf("\t%s => {\n\t\ty => [ %s ],\n\t\tg => [ %s ],\n\t},\n", s, num(d$y),
                if (is.numeric(d$g)) num(d$g) else str(d$g)))
}

# [ set, Df_effect, SS_effect, SS_resid, MS_resid, eta_sq, omega_sq ]
cat("== @R_ROWS\n")
for (s in names(sets)) {
    d <- sets[[s]]
    t <- summary(aov(d$y ~ factor(d$g)))[[1]]
    ss <- t[["Sum Sq"]]; df <- t[["Df"]]; ms <- t[["Mean Sq"]]
    eta <- ss[1] / (ss[1] + ss[2])
    omega <- (ss[1] - df[1] * ms[2]) / (ss[1] + ss[2] + ms[2])
    cat(sprintf("\t[ '%s', %d, %.17g, %.17g, %.17g, %.17g, %.17g ],\n",
                s, as.integer(df[1]), ss[1], ss[2], ms[2], eta, omega))
}

# What the same data give fitted with g as a slope -- what eta_squared() did
# with numeric codes through 0.3217 -- for the comment in the test.
cat("== as a slope\n")
d <- sets$airquality
t <- summary(aov(d$y ~ d$g))[[1]]
cat(sprintf("# airquality, Month as a slope: eta_sq %.4f on %d df\n",
            t[["Sum Sq"]][1] / sum(t[["Sum Sq"]]), as.integer(t[["Df"]][1])))

cat("== warpbreaks\n")
cat(sprintf("\tbreaks  => [ %s ],\n\twool    => [ %s ],\n\ttension => [ %s ],\n",
            num(warpbreaks$breaks), str(warpbreaks$wool), str(warpbreaks$tension)))
