# Generates the expected values frozen in t/predict.offset.R.t.  Run: Rscript t/predict.offset.R.R (R 4.6.1).
options(digits=17)
d=data.frame(y=c(1.2,2.9,3.1,4.8,5.2,6.9,7.1,8.4,9.9,10.3,11.8,12.1),
 x=c(1,2.5,3,4.5,5,6.5,7,8.5,9,10.5,11,12.5),
 z=c(2,3,5,4,6,8,7,9,12,11,13,15.5), a=rep(c("p","q","r"),4))
nd=data.frame(x=c(2.5,6.5,9.5), z=c(3.5,6,10), a=c("q","p","r"))
m=lm(y~x+offset(z/2),d); cat("lm",sprintf("%.17g",predict(m,nd)),"\n")
m=lm(y~a+x+offset(log(z)),d); cat("lm a",sprintf("%.17g",predict(m,nd)),"\n")
dc=data.frame(y=c(1,3,2,6,4,9,7,12,8,15,11,20),x=d$x,z=d$z)
m=glm(y~x+offset(log(z)),family=poisson,data=dc)
cat("glm link",sprintf("%.17g",predict(m,nd,type="link")),"\n")
cat("glm resp",sprintf("%.17g",predict(m,nd,type="response")),"\n")
