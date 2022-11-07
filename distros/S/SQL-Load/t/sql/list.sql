CREATE TABLE users (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR (50) NOT NULL,
    email VARCHAR (100) NOT NULL,
    username VARCHAR (40) NOT NULL,
    password VARCHAR (64) NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE articles (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    title VARCHAR (255) NOT NULL,
    data TEXT NOT NULL,
    created TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);

INSERT INTO users (name, email, username, password) 
     VALUES ('John', 'john@email.com', 'john', 'john12345');
     
INSERT INTO articles (name, user_id, title, data)
     VALUES (
                'Example article', 
                1, 
                '
                    <h1>Example article</h1>
                    <h3>This article is about foo, bar and baz...</h3>
                    
                    <p>...</p>
                ',
                NOW()
            );
